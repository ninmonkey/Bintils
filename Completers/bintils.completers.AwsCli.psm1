using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.ObjectModel
# [Collections.ObjectModel.ReadOnlyCollection[CommandElementAst]]

$script:__moduleConfig = @{

}

function Bintils.AwsCli.Help {
    [Alias('Aws.Help')]
    [CmdletBinding()]
    param()

    $docRecord = @{ TopicName = 'AwsCli_Reference'
        Description = 'top-level AwsCli reference' }
    $DocRecord.Contents = @( @"

AwsVersion: $(aws --version)
"@ )
    $DocRecord.Contents | Join-String -sep "`n" | Write-information -infa 'Continue'
    return [pscustomobject]$docRecord
}
function Bintils.AwsCli.GetConfigObject {
    <#
    .SYNOPSIS

    .EXAMPLE
        Bintils.AwsCli.GetConfigObject
    .EXAMPLE
    #>
    [Alias('Aws.ConfigObject')]
    param()

    return [pscustomobject]@{
        ConfigFolder = gi (Join-path '~' '/.aws')
        Config = gi (Join-Path '~' '/.aws/config')
    }
}
class AwsCliBintilsCompletionResult {
    [CompletionResult]$Completion
    [string]$ParentName = [string]::empty

    [CompletionResult] ToCompletion() {
        # if you need a raw completion
        return $This.Completion
    }
}

function New.Bintil.CompletionResult {
    [Alias(
        'New.AwsBintil.CR',
        'New.AwsCR',
        'AwsCli.New-BintilCompletion'
    )]
    [OutputType([AwsCliBintilsCompletionResult])]
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
        [string[]]$Tooltip,
        [string]$ParentName = ''
    )
    [System.ArgumentException]::ThrowIfNullOrWhiteSpace( $ListItemText , 'ListItemText' )

    $Tooltip =  $Tooltip -join "`n"
    if( [string]::IsNullOrEmpty( $Tooltip )) {
        $Tooltip = '[⋯]'
    }
    if( [string]::IsNullOrEmpty( $CompletionText )) {
        $CompletionText = $ListItemText
    }
    $cr = [CompletionResult]::new(
        <# completionText: #> $completionText,
        <# listItemText  : #> $listItemText,
        <# resultType    : #> $resultType,
        <# toolTip       : #> $toolTip)

    return [AwsCliBintilsCompletionResult]@{
        Completion = $cr
        ParentName = $ParentName ?? ''
    }

    # if( $AsBaseType ) { return $cr }

    # $addMemberSplat = @{
    #     NotePropertyName = 'ParentName'
    #     NotePropertyValue = $PaarentName
    #     PassThru = $true
    #     Force = $true
    # }
    # $cr | Add-Member @addMemberSplat
}

function __module.AwsCli.OnInit {
    'loading completer AwsCli....' | write-host -fg '#c186c1' -bg '#6f7057'
    $PSCommandPath | Join-String -op 'Bitils::init luclidLink completer: {0}' | write-verbose
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

function __module.AwsCli.buildCompletions {
    <#
    .example
        wsl --distribution 'ubuntu' -- pwsh -nop -C 'get-childitem'
    .example
        wsl --distribution 'ubuntu' -- man apt-get
    .example
        wsl --distribution 'ubuntu' -- ls --color=always
    #>
    param()
    @(
        New.Bintil.CompletionResult -Text 'CliAutoPrompt' -Replacement '--cli-auto-prompt' -ResultType ParameterValue -Tooltip 'force prompt'
        New.Bintil.CompletionResult -Text 'NoCliAutoPrompt' -Replacement '--no-cli-auto-prompt' -ResultType ParameterValue -Tooltip 'disable prompt, required for commands like docker login'
# '@
#         New.Bintil.CompletionResult -Text 'Example.Run' -Replacement "run --interactive --tty ubuntu /bin/bash" -ResultType ParameterValue -Tooltip @'
# see:

# - https:// foo.com
#     > docker  run --interactive --tty ubuntu /bin/bash
#     > docker  run -i -t ubuntu /bin/bash     # abbr


#     > docker  pull ubuntu            # implicitly runs
#     > docker  container create
# '@

    )
    # | Sort-Object 'ListItemText' -Unique
    | Sort-Object 'CompletionText' -Unique
    | __SortIt.WithoutPrefix 'ListItemText'
}
class AwsCliProfileNameCompleter : IArgumentCompleter {
    # hidden [hashtable]$Options = @{
        # CompleteAs = 'Name'
    # }
    # hidden [string]$CompleteAs = 'Name'
    # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
    # AwsCliProfileNameCompleter([int] $from, [int] $to, [int] $step) {
    AwsCliProfileNameCompleter( ) { }
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [CommandAst] $commandAst,
        [IDictionary] $fakeBoundParameters) {

        [List[CompletionResult]]$found = @(
                $records = lucid log --list --json
                    | ConvertFrom-Json -AsHashtable
                    | % Keys | Sort-Object -Unique | %{
                        New.Cr -ListItemText $_ -CompletionText $_ -ResultType ParameterValue -Tooltip "mode here"
                    }

                # (Bintils.AwsCli.Parse.Logs -AsObject -infa Ignore).Keys | Sort-Object -Unique
                # | ?{ $_ -match $wordToComplete }
            ) | ?{
                 $_.ListItemText -match $WordToComplete
             }
        $found | ConvertTo-Json | Add-Content 'temp:\last.log' -ea 'continue'
        return $found
    }
}
class AwsCliProfileNameCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [AwsCliProfileNameCompletionsAttribute]::new()
        Pwsh> [AwsCliProfileNameCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    [hashtable]$Options = @{}
    AwsCliProfileNameCompletionsAttribute() { }

    [IArgumentCompleter] Create() {
        return [AwsCliProfileNameCompleter]::new()
    }
}


class AwsCliCompleter : IArgumentCompleter {

    # hidden [hashtable]$Options = @{
        # CompleteAs = 'Name'
    # }
    # hidden [string]$CompleteAs = 'Name'
    # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
    # AwsCliCompleter([int] $from, [int] $to, [int] $step) {
    AwsCliCompleter( ) {
        # $This.Options = @{
        #     # ExcludeDateTimeFormatInfoPatterns = $true
        #     CompleteAs = 'Name'
        # }

        # $this.Options
        #     | WriteJsonLog -Text '🚀 [AwsCliCompleter]::ctor'
    }
    # AwsCliCompleter( $options ) {
    # AwsCliCompleter( $SomeParam = $false ) {
    # AwsCliCompleter( [string]$CompleteAs = 'Name'  ) {
        # $this.SomeParam = $SomeParam
        # $This.Options.CompleteAs = $CompleteAs
        # $This.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text '🚀 [AwsCliCompleter]::ctor | SomeParam'

        # $PSCommandPath | Join-String -op 'not finished: Exclude property is not implemented yet,  ' | write-warning

        # $this.Options = $Options ?? @{}
        # $Options
            # | WriteJsonLog -Text '🚀 [AwsCliCompleter]::ctor'
        # if ($from -gt $to) {
        #     throw [ArgumentOutOfRangeException]::new("from")
        # }
        # $this.From = $from
        # $this.To = $to
        # $this.Step = $step -lt 1 ? 1 : $step

    # }
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
                __module.AwsCli.buildCompletions
            )
        return $found
    }

}

class AwsCliCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [AwsCliCompletionsAttribute]::new()
        Pwsh> [AwsCliCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    [hashtable]$Options = @{}
    AwsCliCompletionsAttribute() {
        # $this.Options = @{
        #     CompleteAs = 'Name'
        # }
        # $this.Options
        #     | WriteJsonLog -Text  '🚀AwsCliCompletionsAttribute::new()'
    }
    AwsCliCompletionsAttribute( [string]$CompleteAs = 'Name' ) {
        # $this.Options.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text  '🚀AwsCliCompletionsAttribute::new | completeAs'
    }

    [IArgumentCompleter] Create() {
        # return [AwsCliCompleter]::new($this.From, $this.To, $this.Step)
        # return [AwsCliCompleter]::new( @{} )
        # '🚀AwsCliCompletionsAttribute..Create()'
        #     | WriteJsonLog -PassThru
            # | .Log -Passthru
        # $This.Options
        #     | WriteJsonLog -PassThru

        return [AwsCliCompleter]::new()
        # if( $This.Options.ExcludeDateTimeFormatInfoPatterns ) {
        #     return [AwsCliCompleter]::new( @{
        #         ExcludeDateTimeFormatInfoPatterns = $This.Options.ExcludeDateTimeFormatInfoPatterns
        #     } )
        # } else {
        #     return [AwsCliCompleter]::new()
        # }
    }
}

$scriptBlockNativeCompleter = {
    # param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    param($wordToComplete, $commandAst, $cursorPosition)
    [List[AwsCliBintilsCompletionResult]]$items = @( __module.AwsCli.buildCompletions )

    $FilterProp =
        'ListItemText' # 'CompletionText'
    [string]$parentName? = $commandAst.CommandElements
        | Select -Last 1 | % value

    $lastName = $commandAst.ToString() -split '\s+' | Select -last 1
    $leftWord = $commandAst.CommandElements | Select -last 1



    [List[Object]]$selected = @(
        $items | ?{
            [bool]$toKeep = (
                ( $_.ParentName -match [regex]::escape( $leftWord ) ) -or
                    ( [string]::IsNullOrWhiteSpace( $_.ParentName ) ) -or
                    ( $_.ParentName -eq 'lucid' ) -or
                    [string]::IsNullOrWhiteSpace( $leftWord ) -or
                    $false
            )
            return $toKeep
        }
    )
        # | ?{
        #     $matchesAny = (
        #         $_.$FilterProp -match $WordToComplete -or
        #         $_.$FilterProp -match [regex]::escape( $WordToComplete ) -or
        #         # // or statically
        #         $_.ListItemText -match $wordToComplete -or
        #         $_.CompletionText -match $wordToComplete -or
        #         $_.ListItemText -match [regex]::escape( $wordToComplete ) -or
        #         $_.CompletionText -match [regex]::escape( $wordToComplete ) )

        #     return $MatchesAny
        # }


    if('based on heirarchy') {
        $crumbs = $commandAst.CommandElements.Value
    }

    if('VerboseLoggingState') {
        $PSStyle.OutputRendering = 'PlainText'

        @(
            "`n ===== Lucid native completion result ==== "
            get-date
            $PSCommandPath |Join-String -op 'source: '
            [ordered]@{
                'Left' = $LeftWord
                'Command' = $PSCommandPath
                'Word' = $WordToComplete
                'Cursor' = $cursorPosition
                'last' = $commandAst.CommandElements[-1]
                'last2' = $commandAst.CommandElements[-2]

            } | Ft -auto | out-String
            $commandAst | Bintils.Common.Format.CommandAst
            "`n"
            "`n"
            $commandAst|ft -AutoSize | Out-string
            $commandAst|fl | Out-string
            "`n"
        )
        | Add-Content -Path 'temp:\completers.log'
        $PSStyle.OutputRendering = 'Ansi'

    }
    $final_CE = [List[CompletionResult]]@( $selected.ToCompletion() ) # should declare an auto coercable  class
    if($final_CE.Count -eq 0){
        [string]$render_tooltip = @(
            'Special 0 matches found, tooltip'
            Join-String -f 'Word: {0}' -in $wordToComplete
            $commandAst | JOin-String -sep ', ' { $_.ToString() }
            Join-String -op 'cusor pos' -In $cursorPosition
        ) | Join-String -sep "`n" -op "debug tooltip`n"
        $final_CE.add(
            [CompletionResult]::new(
                <# completionText: #> '😢',
                <# listItemText: #> '😢',
                <# resultType: #> [CompletionResultType]::Text,
                <# toolTip: #> $render_tooltip)
        )
    }

    return $final_CE

}
__module.AwsCli.OnInit
Register-ArgumentCompleter -CommandName 'Aws' -Native -ScriptBlock $ScriptBlockNativeCompleter -Verbose

# note: Aws.* will export if you import this module directly
# but importing bintils itself, will not export
export-moduleMember -function @(
    'Aws.*'
    'AwsCli.*'
    'Bintils.AwsCli.*'
) -Alias @(
    'Aws.*'
    'AwsCli.*'
    'Bintils.AwsCli.*'
)
