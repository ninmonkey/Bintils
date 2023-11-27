using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$script:__moduleConfig = @{
    Debug_ExportPrivateFunctions = $false
}

function Bintils.Wsl.Help  {
    Get-Command -m Bintils.completers.wsl
    'https://learn.microsoft.com/en-us/windows/wsl/setup/environment'
    'try: __module.Wsl.buildCompletions'
}
function New.CompletionResult {
    [Alias('New.CR')]
    param(
        # original base text
        [Alias('Item', 'Text')]
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateNotNullOrWhiteSpace()]
        [string]$ListItemText,

        # actual value used in replacement, if not the same as ListItem
        [AllowEmptyString()]
        [AllowNull()]
        [Alias('Replacement', 'Replace')]
        [Parameter()]
        [string]$CompletionText,

        # Is there a better default?
        [Parameter()]
        [CompletionResultType]
        $ResultType  = ([CompletionResultType]::ParameterValue),

        # multi-line text displayed when using listcompletion
        [Parameter()]
        [Alias('Description', 'Help', 'RenderText')]
        [string[]]$Tooltip
    )
    [System.ArgumentException]::ThrowIfNullOrWhiteSpace( $ListItemText , 'ListItemText' )

    $Tooltip =  $Tooltip -join "`n"
    if( [string]::IsNullOrEmpty( $Tooltip )) {
        $Tooltip = '[⋯]'
    }
    if( [string]::IsNullOrEmpty( $CompletionText )) {
        $CompletionText = $ListItemText
    }
    [CompletionResult]::new(
        <# completionText: #> $completionText,
        <# listItemText  : #> $listItemText,
        <# resultType    : #> $resultType,
        <# toolTip       : #> $toolTip)
}

function __module.Wsl.OnInit {
    'loading completer wsl....' | write-host -fg '#c186c1' -bg '#6f7057'

    $PSCommandPath | Join-String -op 'Bitils::init wsl completer: {0}' | write-verbose
}
function __SortIt.WithoutPrefix {
    # future: can completer take arguments to the sorting interface? else make it work with one of them
    param(
        [ArgumentCompletions(
            'ListItemText',
            'CompletionText')]
        [string]$PropertyName = 'ListItemText'
    )
    $Input | Sort-Object { $_.$PropertyName -replace '^-+', '' }
}

function __module.Wsl.buildCompletions {@(

    New.CompletionResult -Text '--distribution' -Replacement '--distribution ''distro''' -ResultType ParameterValue -Tooltip @'
--distribution, -d <Distro>
    Run the specified distribution.
'@
#     New.CompletionResult -Text '--user' -Replacement '--user ''UserName''' -ResultType ParameterValue -Tooltip @'
# --user, -u <UserName>
#     Run as the specified user.
# '@
#     New.CompletionResult -Text '--system' -Replacement '' -ResultType ParameterValue -Tooltip @'
# --system
#     Launches a shell for the system distirbution
# '@
#     New.CompletionResult -Text '--debug-shell' -Replacement '' -ResultType ParameterValue -Tooltip 'WSL2 debug session'

#     New.CompletionResult -Text 'List.Online' -Replacement '--list --online' -ResultType ParameterValue -Tooltip 'list online'

#     New.CompletionResult -Text '--install' -Replacement '--install ''distro'' ''options''' -ResultType ParameterValue -Tooltip @'
#  --install [Distro] [Options...]
#         Install a Windows Subsystem for Linux distribution.
#         For a list of valid distributions, use 'wsl.exe --list --online'.

#         Options:
#             --no-launch, -n
#                 Do not launch the distribution after install.

#             --web-download
#                 Download the distribution from the internet instead of the Microsoft Store.

#             --no-distribution
#                 Only install the required optional components, does not install a distribution.
# '@

#     New.CompletionResult -Text '--' -Replacement '' -ResultType ParameterValue -Tooltip @'
# --
#     pass remaning command as-is
# '@

#     New.CompletionResult -Text '--cd' -Replacement "--cd 'Directory'" -ResultType ParameterValue -Tooltip @'
# --cd <Directory>
#     Sets the specified directory as the current working directory.
#     If ~ is used the Linux user's home path will be used. If the path begins
#     with a / character, it will be interpreted as an absolute Linux path.
#     Otherwise, the value must be an absolute Windows path.
# '@

#     New.CompletionResult -Text '--exec' -Replacement '' -ResultType ParameterValue -Tooltip @"
# --exec, -e <CommandLine>
#     Execute the specified command without using the default Linux shell.
# "@
#     New.CompletionResult -Text '--shell-type' -Replacement "--shell-type '<standard|login|none>'" -ResultType ParameterValue -Tooltip @"
# --shell-type <standard|login|none>
#         Execute the specified command with the provided shell type.
# "@

#     New.CompletionResult -Text '--help' -Replacement '--help' -ResultType ParameterValue -Tooltip '...'
#     New.CompletionResult -Text 'help' -Replacement '--help' -ResultType ParameterValue -Tooltip '...'
#     New.CompletionResult -Text '--list' -Replacement '--list' -ResultType ParameterValue -Tooltip @(
# @'
#     --list, -l [Options]
#      Lists distributions.

#      Options:
#          --all
#              List all distributions, including distributions that are
#              currently being installed or uninstalled.

#          --running
#              List only distributions that are currently running.

#          --quiet, -q
#              Only show distribution names.

#          --verbose, -v
#              Show detailed information about all distributions.

#          --online, -o
#              Displays a list of available distributions for install with 'wsl.exe --install'.
# '@
#         )

    )
    | Sort-Object 'ListItemText' -Unique
    | __SortIt.WithoutPrefix 'ListItemText'
}

function Bintils.Wsl.Pipe.AndFixEncoding {
    <#
    .SYNOPSIS
        wsl always outputs utf-16-le, this captures and outputs using the current encoding
    .NOTES
    wsl.exe always outputs it's bytes as UTF-16-LE. When PowerShell encodes those bytes it' uses the console encoding set so the \x00 in the output is typically seen as [char]0
    .EXAMPLE
        $Dest = gi 'H:\data\2023\pwsh\PsModules\Bintils\wsl.help.txt'
        Bintils.Wsl.Pipe.AndFixEncoding
            | set-content $Dest -PassThru -NoNewline
    #>
    param(
        [Parameter()]
        [Alias('Args', 'ArgList')]
        [object[]]$ArgumentList = @('--help')
    )
    [List[Object]]$binArgs = @()
    $binArgs.AddRange(@( $ArgumentList ))
    $binArgs | Join-String -sep ' ' -op 'Invoking wsl with pipeEncodingFix /w args = '
        | write-verbose

    $lastEnc = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $info =
            & wsl @binArgs
    }
    finally {
        [console]::OutputEncoding = $lastEnc
    }
    $info | Join-String -sep "`n"
}

class WslCompleter : IArgumentCompleter {

    # hidden [hashtable]$Options = @{
        # CompleteAs = 'Name'
    # }
    # hidden [string]$CompleteAs = 'Name'
    # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
    # WslCompleter([int] $from, [int] $to, [int] $step) {
    WslCompleter( ) {
        # $This.Options = @{
        #     # ExcludeDateTimeFormatInfoPatterns = $true
        #     CompleteAs = 'Name'
        # }

        # $this.Options
        #     | WriteJsonLog -Text '🚀 [WslCompleter]::ctor'
    }
    # WslCompleter( $options ) {
    # WslCompleter( $SomeParam = $false ) {
    WslCompleter( [string]$CompleteAs = 'Name'  ) {
        # $this.SomeParam = $SomeParam
        # $This.Options.CompleteAs = $CompleteAs
        # $This.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text '🚀 [WslCompleter]::ctor | SomeParam'

        # $PSCommandPath | Join-String -op 'not finished: Exclude property is not implemented yet,  ' | write-warning

        # $this.Options = $Options ?? @{}
        # $Options
            # | WriteJsonLog -Text '🚀 [WslCompleter]::ctor'
        # if ($from -gt $to) {
        #     throw [ArgumentOutOfRangeException]::new("from")
        # }
        # $this.From = $from
        # $this.To = $to
        # $this.Step = $step -lt 1 ? 1 : $step

    }
    <#
    .example

    > try.Named.Fstr yyyy'-'MM'-'dd'T'HH':'mm':'ssZ
    GitHub.DateTimeOffset  ShortDate (Default)    LongDate (Default)

        Git Dto ⁞ 2023-11-11T18:58:42Z
        yyyy'-'MM'-'dd'T'HH':'mm':'ssZ
        Github DateTimeZone
        Github DateTimeOffset UTC
    #>

    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [CommandAst] $commandAst,
        [IDictionary] $fakeBoundParameters) {

        # [List[CompletionResult]]$resultList = @()
        # $DtNow = [datetime]::Now
        # $DtoNow = [DateTimeOffset]::Now
        # [bool]$NeverFilterResults = $false
        # $Config = @{
        #     # IncludeAllDateTimePatterns = $true
        #     # IncludeFromDateTimeFormatInfo = $true
        # }
        # todo: pass query string filter
        [List[CompletionResult]]$found = @(
                __module.Wsl.buildCompletions
            )
        return $found
    }

}

class WslCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [WslCompletionsAttribute]::new()
        Pwsh> [WslCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    [hashtable]$Options = @{}
    WslCompletionsAttribute() {
        # $this.Options = @{
        #     CompleteAs = 'Name'
        # }
        # $this.Options
        #     | WriteJsonLog -Text  '🚀WslCompletionsAttribute::new()'
    }
    WslCompletionsAttribute( [string]$CompleteAs = 'Name' ) {
        # $this.Options.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text  '🚀WslCompletionsAttribute::new | completeAs'
    }

    [IArgumentCompleter] Create() {
        # return [WslCompleter]::new($this.From, $this.To, $this.Step)
        # return [WslCompleter]::new( @{} )
        # '🚀WslCompletionsAttribute..Create()'
        #     | WriteJsonLog -PassThru
            # | .Log -Passthru
        # $This.Options
        #     | WriteJsonLog -PassThru

        return [WslCompleter]::new()
        # if( $This.Options.ExcludeDateTimeFormatInfoPatterns ) {
        #     return [WslCompleter]::new( @{
        #         ExcludeDateTimeFormatInfoPatterns = $This.Options.ExcludeDateTimeFormatInfoPatterns
        #     } )
        # } else {
        #     return [WslCompleter]::new()
        # }
    }
}
function Bintils.Debug.Wsl.TestCompleter {
    'testing completer....' | write-host -fg 'magenta'
}

function Bintils.Invoke.WslWithCompletions {
    [Alias(
        'bin.Wsl',
        'b.Wsl'
    )]
    param(
        [Parameter()]
        [WslCompletionsAttribute()]
        [string]$Commands
    )
    write-warning 'attribute not fully working yet'

    'invoking wsl' | write-host -back 'magenta'
}

$scriptBlock = {
    # param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    param($wordToComplete, $commandAst, $cursorPosition)
    [List[CompletionResult]]$items = @( __module.Wsl.buildCompletions )

    $FilterProp =
        'ListItemText'
        'CompletionText'

    [List[CompletionResult]]$selected =
        $items | ?{
            $matchesAny = (
                $_.ListItemText -match $wordToComplete -or
                $_.CompletionText -match $wordToComplete -or
                $_.ListItemText -match [regex]::escape( $wordToComplete ) -or
                $_.CompletionText -match [regex]::escape( $wordToComplete ) )

            return $MatchesAny
        }

    return $selected
}
__module.Wsl.OnInit
'Register-ArgumentCompleter -CommandName ''wsl''' | write-host -fg 'orange'
Register-ArgumentCompleter -CommandName 'wsl' -Native -ScriptBlock $ScriptBlock -Verbose


Bintils.Debug.Wsl.TestCompleter

# extra export types?
if($script:__moduleConfig.Debug_ExportPrivateFunctions) {
    write-warning 'extra config enabled: $script:__moduleConfig.Debug_ExportPrivateFunctions'
    export-moduleMember -function @(
        'Wsl*'
    ) -Alias @(
        'Wsl*'
    )
}
# Export-ModuleMember -Function @(
#     'Bintils.*'
# ) -Alias @(
#     'Bintils.*'
# ) -Variable @(
#     'Bintils*'
# )
