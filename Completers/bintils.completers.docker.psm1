using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$script:__moduleConfig = @{

}

function Bintils.Docker.Wsl.Help  {
    Get-Command -m Bintils.completers.Docker
    'try: __module.Docker.buildCompletions'
    '- [Build Cache](https://docs.docker.com/build/cache/)'
    'https://docs.docker.com/build/building/multi-stage/#use-an-external-image-as-a-stage'
    'https://docs.docker.com/build/building/multi-stage/#differences-between-legacy-builder-and-buildkit'
    'try'
    @(
        '#docker'
        "type 'log<tab> build.stag<tab>'  # then alt+a and ctrl+z for fancy reverse"
    )


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

function __module.Docker.OnInit {
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

function __module.Docker.buildCompletions {
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

        New.CompletionResult -Text 'Log.Debug' -Replacement "--log-level=debug" -ResultType ParameterValue -Tooltip ''
        New.CompletionResult -Text 'Example.Build.Stage' -Replacement "docker build --target build --tag hello ." -ResultType ParameterValue -Tooltip ''

        New.CompletionResult -Text 'Example.Build' -Replacement "build --tag welcome-to-docker ." -ResultType ParameterValue -Tooltip @'
see:

- https://docs.docker.com/guides/walkthroughs/run-a-container/
- https://docs.docker.com/engine/reference/commandline/build/

    > build --tag welcome-to-docker .
    > build -t welcome-to-docker .      # abbr


'@
        New.CompletionResult -Text 'Example.Run' -Replacement "run --interactive --tty ubuntu /bin/bash" -ResultType ParameterValue -Tooltip @'
see:

- https://docs.docker.com/get-started/overview/#example-docker-run-command
- https://docs.docker.com/engine/reference/commandline/run/

    > docker run --interactive --tty ubuntu /bin/bash
    > docker run -i -t ubuntu /bin/bash     # abbr


    > docker pull ubuntu            # implicitly runs
    > docker container create
'@

    )
    # | Sort-Object 'ListItemText' -Unique
    | Sort-Object 'CompletionText' -Unique
    | __SortIt.WithoutPrefix 'ListItemText'
}

# function Bintils.Docker.Wsl.Pipe.AndFixEncoding {
#     <#
#     .SYNOPSIS
#         wsl always outputs utf-16-le, this captures and outputs using the current encoding
#     .NOTES
#     wsl.exe always outputs it's bytes as UTF-16-LE. When PowerShell encodes those bytes it' uses the console encoding set so the \x00 in the output is typically seen as [char]0
#     .EXAMPLE
#         $Dest = gi 'H:\data\2023\pwsh\PsModules\Bintils\wsl.help.txt'
#         Bintils.Docker.Wsl.Pipe.AndFixEncoding
#             | set-content $Dest -PassThru -NoNewline
#     #>
#     param(
#         [Parameter()]
#         [ArgumentCompletions(
#             '--help',
#             "'--list', '--running'"
#         )]
#         [Alias('Args', 'ArgList')]
#         [object[]]$ArgumentList = @('--help')
#     )
#     throw 'replaced by: "Bintils.Docker.Wsl.Stream"'
#     [List[Object]]$binArgs = @()
#     $binArgs.AddRange(@( $ArgumentList ))
#     $binArgs | Join-String -sep ' ' -op 'Invoking wsl with pipeEncodingFix /w args = '
#         | write-verbose

#     $lastEnc = [Console]::OutputEncoding
#     try {
#         [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
#         $info =
#             & wsl @binArgs
#     }
#     finally {
#         [console]::OutputEncoding = $lastEnc
#     }
#     $info | Join-String -sep "`n"
# }
function Bintils.Docker.Wsl.Stream {
    <#
    .SYNOPSIS
        wsl always outputs utf-16-le, this captures and outputs using the current encoding
    .NOTES
    wsl.exe always outputs it's bytes as UTF-16-LE. When PowerShell encodes those bytes it' uses the console encoding set so the \x00 in the output is typically seen as [char]0
    .EXAMPLE
        $Dest = gi 'H:\data\2023\pwsh\PsModules\Bintils\wsl.help.txt'
        Bintils.Docker.Wsl.Pipe.AndFixEncoding
            | set-content $Dest -PassThru -NoNewline
    .LINK
        Bintils.Docker.Wsl.Stream
    .LINK
        H:\data\2023\pwsh\PsModules.👨.Import\Jaykul👨\Jaykul👨Invoke-Native\Jaykul👨Invoke-Native.psm1
    #>
    param(
        [Parameter()]
        [ArgumentCompletions(
            '--help',
            "'--list', '--running'"
        )]
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
        & wsl @binArgs
        # | %{
        #     $_
        # }
    }
    finally {
        [console]::OutputEncoding = $lastEnc
    }
    # $info | Join-String -sep "`n"
}

$updateTypeDataSplat = @{
    Force = $true
    TypeName = 'Bintils.Docker.Image.ParsedResult'
    DefaultDisplayPropertySet = @(
        'Repository',
        'Tag',
        'Created',
        'Size',
        'ImageId'
    )
}

Update-TypeData @updateTypeDataSplat

function Bintils.Docker.Parse.Images {
    <#
    .SYNOPSIS
        parse docker images command
    .EXAMPLE
        Pwsh> Bintils.Docker.Parse.Images
    .EXAMPLE
        Pwsh> Bintils.Docker.Parse.Images -ListRepoNames

            <none>
            custom-docker
            public.ecr.aws/amazonlinux/amazonlinux
            public.ecr.aws/lambda/provided
            public.ecr.aws/sam/build-provided.al2
            public.ecr.aws/sam/build-provided.al2023
    .EXAMPLE
        Pwsh> Bintils.Docker.Parse.Images -SummarizeCounts

        Count Name
        ----- ----
            39 <none>
            18 public.ecr.aws/lambda/provided
            6 public.ecr.aws/sam/build-provided.al2
            3 samcli/lambda-provided
            2 public.ecr.aws/amazonlinux/amazonlinux
            1 custom-docker
            1 public.ecr.aws/sam/build-provided.al2023
            1 ubuntu
            1 welcome-to-docker
    .notes

    Usage:  docker images [OPTIONS] [REPOSITORY[:TAG]]

    List images

        Options:
        -a, --all             Show all images (default hides intermediate images)
            --digests         Show digests
        -f, --filter filter   Filter output based on conditions provided
            --format string   Pretty-print images using a Go template
            --no-trunc        Don't truncate output
        -q, --quiet           Only show image IDs
    #>
    param(
        # docker images --all
        [Alias('IncludeIntermediateImages')]
        [switch]$All,
        [switch]$ReplaceNoneString,

        # return only the distinct values
        [switch]$ListRepoNames,

        # return only the distinct values
        [switch]$ListTagNames,

        [switch]$SummarizeCounts,

        [ValidateSet(
            'Repository',
            'Tag',
            'Created',
            'Size',
            'ImageId'
        )]
        [string]$SortBy
    )
    [List[Object]]$BinArgs = @(
        'images'
        if($All) { '--all' }
        # '--digests'
        '--no-trunc'
    )
    $Options = @{
        ReplaceNoneString = $ReplaceNoneString # $true
    }

    if($SortyBy -in @('Created', 'Size')) {
        Write-warning 'NYI: todo: parse Created and Size to numerical types'
    }

    $lines = & docker @BinArgs
        | Select -Skip 1
    $regex = @{}
    $Regex.Line = @'
(?x)
^
    (?<Repository>
        .*?
    )
    # always 3+spaces delims
    \s{3,}
    (?<Tag>
        .*?
    )
    \s{3,}
    (?<ImageId>
        .*?
    )
    \s{3,}
    (?<Created>
        .*?
    )
    \s{3,}
    (?<Size>
        .*?
    )
$
'@
    $regex.NoneString = [regex]::escape('<none>')
    $found = $Lines | %{
        $curLine = $_
        if($_ -match $Regex.Line) {
            $matches.remove(0)
            $meta = [hashtable]::new($matches)
            $meta.PSTypeName = 'Bintils.Docker.Image.ParsedResult'

            if($Options.ReplaceNoneString) {
                $meta.Tag = $meta.Tag -replace $regex.NoneString, ''
                $meta.Repository = $meta.Repository -replace $regex.NoneString, ''
            }
            [pscustomobject]$meta
        } else {
            'failed parsing line: {0}' -f $curLine
                | write-warning
        }
    }

    if($SummarizeCounts)  {
        $Found
            | Group-Object Repository -NoElement
            | Sort-Object Count -Descending | ft -AutoSize
            | Out-String
            | write-host

        $Found
            | Group-Object Tag -NoElement
            | Sort-Object Count -Descending | ft -AutoSize
            | Out-String
            | write-host
        return
    }

    if($ListRepoNames){
        return $found.Repository | Sort-Object -unique
    }
    if($ListTagNames){
        return $found.Tag | Sort-Object -unique
    }

    if($PSBoundParameters.ContainsKey('Sortby')) {
        return $found | Sort-Object -p $SortBy
    }

    return $found

}

class DockerCompleter : IArgumentCompleter {

    # hidden [hashtable]$Options = @{
        # CompleteAs = 'Name'
    # }
    # hidden [string]$CompleteAs = 'Name'
    # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
    # DockerCompleter([int] $from, [int] $to, [int] $step) {
    DockerCompleter( ) {
        # $This.Options = @{
        #     # ExcludeDateTimeFormatInfoPatterns = $true
        #     CompleteAs = 'Name'
        # }

        # $this.Options
        #     | WriteJsonLog -Text '🚀 [DockerCompleter]::ctor'
    }
    # DockerCompleter( $options ) {
    # DockerCompleter( $SomeParam = $false ) {
    DockerCompleter( [string]$CompleteAs = 'Name'  ) {
        # $this.SomeParam = $SomeParam
        # $This.Options.CompleteAs = $CompleteAs
        # $This.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text '🚀 [DockerCompleter]::ctor | SomeParam'

        # $PSCommandPath | Join-String -op 'not finished: Exclude property is not implemented yet,  ' | write-warning

        # $this.Options = $Options ?? @{}
        # $Options
            # | WriteJsonLog -Text '🚀 [DockerCompleter]::ctor'
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
                __module.Docker.buildCompletions
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
        # return [DockerCompleter]::new($this.From, $this.To, $this.Step)
        # return [DockerCompleter]::new( @{} )
        # '🚀WslCompletionsAttribute..Create()'
        #     | WriteJsonLog -PassThru
            # | .Log -Passthru
        # $This.Options
        #     | WriteJsonLog -PassThru

        return [DockerCompleter]::new()
        # if( $This.Options.ExcludeDateTimeFormatInfoPatterns ) {
        #     return [DockerCompleter]::new( @{
        #         ExcludeDateTimeFormatInfoPatterns = $This.Options.ExcludeDateTimeFormatInfoPatterns
        #     } )
        # } else {
        #     return [DockerCompleter]::new()
        # }
    }
}
function Bintils.Debug.Docker.TestCompleter {
    'testing docker completer....' | write-host -fg 'magenta'
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
    [List[CompletionResult]]$items = @( __module.Docker.buildCompletions )

    $FilterProp =
        'ListItemText' # 'CompletionText'

    [List[CompletionResult]]$selected =
        $items | ?{
            $matchesAny = (
                $_.$FilterProp -match $WordToComplete -or
                $_.$FilterProp -match [regex]::escape( $WordToComplete ) -or
                # // or statically
                $_.ListItemText -match $wordToComplete -or
                $_.CompletionText -match $wordToComplete -or
                $_.ListItemText -match [regex]::escape( $wordToComplete ) -or
                $_.CompletionText -match [regex]::escape( $wordToComplete ) )

            return $MatchesAny
        }

    return $selected
}
__module.Docker.OnInit
Register-ArgumentCompleter -CommandName 'docker' -Native -ScriptBlock $ScriptBlock -Verbose


# Bintils.Debug.Docker.TestCompleter

# extra export types?
if($script:__moduleConfig.Debug_ExportPrivateFunctions) {
    write-warning 'extra config enabled: $script:__moduleConfig.Debug_ExportPrivateFunctions'
    export-moduleMember -function @(
        'Docker.*'
        'Bintils.Docker.*'
    ) -Alias @(
        'Docker.*'
        'Bintils.Docker.*'
    )
}
# Export-ModuleMember -Function @(
#     'Bintils.*'
# ) -Alias @(
#     'Bintils.*'
# ) -Variable @(
#     'Bintils*'
# )
