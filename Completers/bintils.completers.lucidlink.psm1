using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.ObjectModel
# [Collections.ObjectModel.ReadOnlyCollection[CommandElementAst]]

$script:__moduleConfig = @{

}

function Bintils.LucidLink.Help {
    [Alias('Lc.Help')]
    [CmdletBinding()]
    param()

    $docRecord = @{ TopicName = 'LucidLinkfile_Reference'
        Description = 'top-level LucidLinkfile reference' }
    $DocRecord.Contents = @( @'

- [Link Filespace with a specific cache and metadata location ](https://support.lucidlink.com/hc/en-us/articles/5778746475149)
- [cli ref: top level commands](https://support.lucidlink.com/hc/en-us/articles/5778955042445-Command-line-feature-functions)
- [performance testing](https://support.lucidlink.com/hc/en-us/articles/5647793046797-Filespace-Performance-Monitoring)
- [cli when running as a service](https://support.lucidlink.com/hc/en-us/articles/5464065047565)
- [backup to a filespace /w Pwsh](https://support.lucidlink.com/hc/en-us/articles/5778582932109-Backup-to-a-Filespace-via-PowerShell-script)
- https://support.lucidlink.com/hc/en-us/articles/5778637880461-Manage-snapshots-PowerShell-script
- [robocopy mirror to sync, force lock](https://support.lucidlink.com/hc/en-us/articles/5778576628493-Synchronize-Production-DR-Filespaces-in-PowerShell)
    - Script links and mounts Production and DR Filespaces as separate instances on the same machine, performs a Robocopy mirror of the complete directory tree to the DR Filespace.
    - Ensures only 1 instance is running, therefore can be scheduled as a task to complete without overlap. Waits on all uploads to complete before synchronizing metadata, file data and unlinking
- [http proxy](https://support.lucidlink.com/hc/en-us/articles/5647687430797-HTTP-proxy-support)
- [link filespace from command line](https://support.lucidlink.com/hc/en-us/articles/5778939271437)

Identifying "disk usage" inside a Linux Filespace mount-point through du -b <path> which will calculate the size of the Filespace in bytes.

Other handy options for `du` are: `-s` (summary), `-h` (human readable), `--max-depth` (specifies folder depth for the final report).

Example: du -bhs <path>

    Please note, that this calculates the size of the Filespace (mount-point) and does not include the disk space, used by the Lucid in cache or metadata (the internal `.lucid`) folder.

## other invokes

    lucid version
    lucid help status
    lucid support


## Invoke shapes:

    # List
    Lucid.exe snapshot

    # Create
    Lucid.exe snapshot --create $name

    # Activate
    Lucid.exe snapshot
    Lucid.exe activate --snapshot $id

    # filespace
    Lucid.exe activate


    # Delete
    Lucid.exe snapshot
    Lucid.exe snapshot --delete $id


'@ )
    $DocRecord.Contents | Join-String -sep "`n" | Write-information -infa 'Continue'
    return [pscustomobject]$docRecord
}
function Bintils.LucidLink.GetConfigObject {
    <#
    .SYNOPSIS
        no params returns all json records else filter
    .EXAMPLE
        Bintils.LucidLink.GetConfigObject
    .EXAMPLE
        Bintils.LucidLink.GetConfigObject -ShowApp
        Bintils.LucidLink.GetConfigObject -ShowLucid
        Bintils.LucidLink.GetConfigObject -ShowInstance
    .EXAMPLE
        (Bintils.LucidLink.GetConfigObject)[1].Data
    .EXAMPLE
        gc (Bintils.LucidLink.GetConfigObject)[1].Path
    #>
    [Alias('LC.ConfigObject')]
    param(

        # no params shows all, this shows app config only
        [switch]$ShowApp,
        # no params shows all, this shows only root config
        [switch]$ShowLucid,

        # no params shows all, this all instance config
        [Alias('ListInstance')]
        [switch]$ShowInstance
    )

    $files = Bintils.LucidLink.FindConfig json | Get-item
    $records = $Files | %{
        $Item = $_
        [pscustomobject]@{
            Name = $Item.BaseName
            Data =
                gc $Item | ConvertFrom-Json -depth 9
            RelativePath =
                 $Item.FullName -replace [regex]::Escape( (gi ~/.lucid).FullName + '\' ), ''
            Path = $item | Get-Item
                # Bintils.LucidLink.FindConfig json | Get-item | %{
        }
    }
    if( $ShowApp ) {
        return $records | ?{
            ($_.relativePath -match 'app\.json') }
    }
    if( $ShowLucid ) {
        return $records | ?{
            ($_.relativePath -match 'Lucid\.json') -and ( $_.RelativePath -notmatch 'instance' ) }
    }
    if( $ShowInstance ) {
        return $records | ?{
            ($_.relativePath -eq 'instance_501\Lucid.json') -or ( $_.RelativePath -match 'instance' ) }

    }
    return $records
}




function Bintils.LucidLink.FindConfig.WithoutFd {
    param(
        [ArgumentCompletions(
            'json', 'log', 'cfg', 'mdb'
        )]
        [string]$FileType
    )

    if(-not $HasFdFind ) {
        gci -path '.'
        '*.{0}'
    }

}
function Bintils.LucidLink.FindConfig {
    [Alias('Lc.FindConfig')]
    param(
        [ArgumentCompletions(
            'json', 'log', 'cfg', 'mdb'
        )]
        [string]$FileType
    )
    # if( -not (Bintils.Common.Test-UserHasNativeCommand 'fd')) {
    if( -not (Bintils.Has-NativeCmd 'fd')) {
        Bintils.LucidLink.FindConfig.WithoutFd
        return
    }

    $binArgs = @(
        '-tf'
        if( $FileType ) { '-e', $FileType }
        '--search-path'
        (gi '~/.lucid' -ea 'Stop')
    )
    Bintils.Common.PreviewArgs $binArgs
    & fd @binArgs
}
function Bintils.LucidLink.GetAppLocations {
    [Alias('Bintils.LucidLink.AppPath')]
    param()
    write-warning 'this is the default location, also test custom locations'
    $meta = [ordered]@{
        AppData = Get-Item (Join-Path $Env:APPDATA 'LucidApp')
        Home = gci ~ *lucid* -Force
    }
    return [pscustomobject]$Meta
}
function Bintils.LucidLink.Parse.Info {
    <#
    .SYNOPSIS
        returns 'lucid info' as a hashtable
    #>
    [Alias(
        'Lc.Info'
    )]
    [OutputType('Hashtable')]
    param()
    [List[Object]]$BinArgs = @(
        'info'
    )
    $BinArgs | Bintils.Common.PreviewArgs
    $meta = [ordered]@{}
    (& lucid @BinArgs) -split '\r?\n'| %{
        $Key, $Value = $_ -split ':\s+', 2
        $meta[ $key ] = $value
    }
    return $meta
}

function __parsing.CmdConfig.AsEffective {
    <#
    .notes

    example text to be parsed:


    Pwsh> lucid config | select -First 4

        KEY NAME                                      EFFECTIVE                        CONFIGURED                       SCOPE        STATUS
        Compressor.Concurrency                        12                               0                                Default
        Compressor.DestageThreshold                   1024                             1024                             Default

    Pwsh> lucid config --effective | select -First 4

        KEY NAME                                      EFFECTIVE                        CONFIGURED                       SCOPE        STATUS
        Compressor.Concurrency                        12                               0                                Default
        Compressor.DestageThreshold                   1024                             1024                             Default

    #>
    param(
        [string[]]$InputText
    )
    $rawStdout = $InputText
    $rawHeaderLine = $rawStdout | select -first 1 -skip 1
    $linesToParse = $rawStdout | Select -skip 2

    $curLine = $rawHeaderLine
    $colName1 = 'KEY NAME'
    $colName2 = 'EFFECTIVE'
    $colName3 = 'CONFIGURED'
    $colName4 = 'SCOPE'
    $colName5 = 'STATUS'
    $EndOfText = $rawStdout

    [regex]::Split( $stdout[0], '\s{3,}') | Join.UL
    
    # $rawHeaderLine.Substring( $from, ($To-$from) )
# $col1 = $curLine.Substring(
    # $linesToParse | %{
        # [string]$curLine = $_

    # todo: Refactor as Bintils.Common.Parse-FixedColumnWidths 2023-12-11

    $lineNum = -1
    foreach($curLine in $LinesToParse) {
        $lineNum++
        if($CurLine.length -eq 0) { continue }
        $ParsedLine = [ordered]@{
            PSTypeName = 'Bintils.LucidLink.ParsedCommand.Config'
        }
        $curLineLength = $curLine.Length
        # $from, $To =
        #     $rawHeaderLine.IndexOf( $colName2 ),
        #     $rawHeaderLine.IndexOf( $colName3 )

        $from = 0
        $to   = $rawHeaderLine.indexOf( $colName2 )
        $curLen = [math]::Clamp(($to - $from),
                                    0, $curLineLength )
        $ParsedLine.$colName1 = $curLine.Substring( $from, $curLen )

        $from = $rawHeaderLine.indexOf( $colName2 )
        $to   = $rawHeaderLine.indexOf( $colName3 )
        $curLen = [math]::Clamp( ($to - $from), 0, $curLineLength )
        if($from -eq -1 -or $to -eq -1 -or ($to - $from) -gt $curLineLength ) {
            write-error "failed Parsing line: LineNum: $lineNum, From: $from, To: $to, Len: $curLineLength, `nText: '$curLine'" }
        $parsedLine.$ColName2 = $curLine.Substring( $from, $curLen )

        $from = $rawHeaderLine.indexOf( $colName3 )
        $to   = $rawHeaderLine.indexOf( $colName4 )
        $curLen = [math]::Clamp( ($to - $from), 0, $curLineLength )
        if($from -eq -1 -or $to -eq -1 -or ($to - $from) -gt $curLineLength ) {
            write-error "failed Parsing line: LineNum: $lineNum, From: $from, To: $to, Len: $curLineLength, `nText: '$curLine'" }
        $parsedLine.$ColName3 = $curLine.Substring( $from, $curLen )

        $from = $rawHeaderLine.indexOf( $colName4 )
        $to   = $rawHeaderLine.indexOf( $colName5 )
        $curLen = [math]::Clamp( ($to - $from), 0, $curLineLength )
        if($from -eq -1 -or $to -eq -1 -or ($to - $from) -gt $curLineLength ) {
            write-error "failed Parsing line: LineNum: $lineNum, From: $from, To: $to, Len: $curLineLength, `nText: '$curLine'" }
        $parsedLine.$ColName4 = $curLine.Substring( $from, $curLen )

        $from = $rawHeaderLine.indexOf( $colName5 )
        $to   = $curLineLength
        $curLen = [math]::Clamp( ($to - $from), 0, $curLineLength )
        if($from -eq -1 -or $to -eq -1 -or ($to - $from) -gt $curLineLength ) {
            write-error "failed Parsing line: LineNum: $lineNum, From: $from, To: $to, Len: $curLineLength, `nText: '$curLine'" }
        $parsedLine.$ColName5 = $curLine.Substring( $from, $curLen )

        [pscustomobject]$ParsedLine
    }
}
function Bintils.LucidLink.Parse.Config {
     <#
    .SYNOPSIS
        returns 'lucid config'
    .example
        # Directly export to excel
        > Lc.Config | Export-Excel
    .notes
        > lucid help config

        lucid config --list [--effective]
        lucid config --list --local
        lucid config --list --global
        lucid config --explain [--KEY1 --KEY2 ...]
        lucid config --set [--local] --KEY1 VALUE1 [--KEY2 VALUE2 ...] [--password adminPassword]
        lucid config --set --global --KEY1 VALUE1 [--KEY2 VALUE2 ...] [--password adminPassword]
        lucid config --delete [--local] --KEY1 [--KEY2 ...] [--password adminPassword]
        lucid config --delete --global --KEY1 [--KEY2 ...] [--password adminPassword]

        --effective              Currently effective filespace configurations for this client
        --local                  Local configurations scope. Affects only client where setting is applied
        --global                 Global configurations scope. Affects each client that connects to the filespace unless overridden with --local for a particular client
        --set                    Set configuration key(s). Defaults to `local` scope
        --delete                 Delete configuration key(s). Defaults to `local` scope
        --password password      An admin user's password. Used with --global and --local options
        --list                   Display the configuration settings per scope
        --no-trim                Do not trim long configuration values
        --explain                Describe what each configuration key affects within Lucid and list its value constraints. Can be used with --KEY

    #>
    [Alias(
        'Lc.Config'
    )]
    # [OutputType('haSHTABLE')]
    param(
        [Parameter(Position=0)]
        [Alias('Scope')]
        [ValidateSet(
            'effective', 'local', 'global', 'default'
        )]
        [string]$ShowScope
    )
    $scopeFlag = if( $PSboundparameters.ContainsKey( 'ShowScope' ) ) {
        switch( $ShowScope ) {
            'global' { '--global' }
            'effective' { '--effective' }
            'local' { '--local' }
            'default' { }
            default { }
        }
    }
    [List[Object]]$BinArgs = @(
        'config'
        '--list'
        '--no-trim'
        # if($PSBoundParameters.c
        $scopeFlag
    )


    $BinArgs | Bintils.Common.PreviewArgs
    $rawStdout = & Lucid @binArgs

    switch($ShowScope) {
        { $_ -in 'effective', 'global' } {
            __parsing.CmdConfig.AsEffective -Lines $rawStdout
        }
        default { throw "UnhandledScope: $ShowInScope"}
    }




    # $rawHeaderLine -match @'
# (?x)
#   ^
#   (?<KeyName>.*?)

#   \s{3,}
#   (?<Effective>.*?)

#   (?<Rest>.*)
# $

# '@
    # try {

    # } catch {
    #     throw
    #     # throw "Lucidlink.Config parsing failed! $_"
    # }
}
function Bintils.LucidLink.Parse.Logs {
    [Alias(
        'Lc.Logs.Parse',
        'Lc.Log'
    )]
    param(
        # this param doesn't fire correctly,
        [Parameter()]
        [LucidLogNameCompletionsAttribute()]
        [string]$LoggerName,

        [ArgumentCompletions(
             'disabled',
             'fatal',
             'critical',
             'error',
             'warning',
             'notice',
             'info',
             'debug',
             'trace'
        )][string]$LogLevel,


        [Alias('All')][switch]$ListAll,

        [Alias('PassThru')]
        [switch]$AsObject,

        [switch]$WithoutJson
    )
    if($AsObject) {
        # $ListAll = $true # maybe?
        $WithoutJson = $false
    }
    if($PSBoundParameters.ContainsKey('LoggerName')) {
        write-warning 'something not 100% on this completer for logname completer'
    }

    if($PSBoundParameters.ContainsKey('AsObject') -and $PSBoundParameters.ContainsKey('LogLevel')) {
         throw 'InvalidArgumentState: Only one of the following options is allowed: json, log-level'
    }

    [List[Object]]$BinArgs = @(
        'log'
        if( $ListAll ) { '--list' }
        if( $LoggerName ) { '--logger' ; $LoggerName }
        if( $LogLevel ) { '--log-level' ; $LogLevel }
        if( ( -not $WithoutJson ) -or $AsObject ) { '--json' }
    )

    if($AsObject) {
        # $BinArgs | Bintils.Common.PreviewArgs
        # lucid log --list --json | ConvertFrom-Json -AsHashtable
        $BinArgs | Bintils.Common.PreviewArgs

        $records = @( & lucid @BinArgs )
            | ConvertFrom-Json -AsHashtable

        return $records
    }

    $BinArgs | Bintils.Common.PreviewArgs
    & lucid @BinArgs
}
class BintilsCompletionResult {
    [CompletionResult]$Completion
    [string]$ParentName = [string]::empty

    [CompletionResult] ToCompletion() {
        # if you need a raw completion
        return $This.Completion
    }
}

function New.Bintil.CompletionResult {
    [Alias(
        'New.Bintil.CR',
        'New.BCR',
        'Bintils.New-BintilCompletion'
    )]
    [OutputType([BintilsCompletionResult])]
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

    return [BintilsCompletionResult]@{
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

function __module.LucidLink.OnInit {
    'loading completer lucidLink....' | write-host -fg '#c186c1' -bg '#6f7057'
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

function __module.LucidLink.buildCompletions {
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
        New.Bintil.CompletionResult -Text 'effective' -Replacement '--effective' -ResultType ParameterValue -Tooltip 'lucid log config --explain' -ParentName 'config'
        New.Bintil.CompletionResult -Text 'explain' -Replacement '--explain' -ResultType ParameterValue -Tooltip 'lucid log config --effective' -ParentName 'config'
        New.Bintil.CompletionResult -Text 'help' -Replacement 'help' -ResultType ParameterValue -Tooltip 'help on topics' -ParentName 'lucid'
    if($false) {
        New.Bintil.CompletionResult -Text 'Support' -Replacement 'support' -ResultType ParameterValue -Tooltip ''
        New.Bintil.CompletionResult -Text 'mount' -Replacement 'mount' -ResultType ParameterValue -Tooltip 'https://support.lucidlink.com/hc/en-us/articles/5778975434765'
        New.Bintil.CompletionResult -Text 'unmount' -Replacement 'unmount' -ResultType ParameterValue -Tooltip 'https://support.lucidlink.com/hc/en-us/articles/5778975434765'
        New.Bintil.CompletionResult -Text 'cache' -Replacement 'cache' -ResultType ParameterValue -Tooltip 'https://support.lucidlink.com/hc/en-us/articles/5467779996173'

        New.Bintil.CompletionResult -Text 'Help.Status' -Replacement 'help status' -ResultType ParameterValue -Tooltip ''
        New.Bintil.CompletionResult -Text 'Help' -Replacement '' -ResultType ParameterValue -Tooltip 'https://support.lucidlink.com/hc/en-us/articles/5778955042445-Command-line-feature-functions'
        New.Bintil.CompletionResult -Text 'Example.Performance.Explain' -Replacement "perf --explain" -ResultType ParameterValue -Tooltip 'https://support.lucidlink.com/hc/en-us/articles/5647793046797-Filespace-Performance-Monitoring'
    }
#         New.Bintil.CompletionResult -Text 'Example.Build.Stage' -Replacement "LucidLink build --target build --tag hello ." -ResultType ParameterValue -Tooltip ''

#         New.Bintil.CompletionResult -Text 'Example.Build' -Replacement "build --tag welcome-to-LucidLink ." -ResultType ParameterValue -Tooltip @'
# see:

# - https://docs.LucidLink.com/guides/walkthroughs/run-a-container/
# - https://docs.LucidLink.com/engine/reference/commandline/build/

#     > build --tag welcome-to-LucidLink .
#     > build -t welcome-to-LucidLink .      # abbr


# '@
#         New.Bintil.CompletionResult -Text 'Example.Run' -Replacement "run --interactive --tty ubuntu /bin/bash" -ResultType ParameterValue -Tooltip @'
# see:

# - https://docs.LucidLink.com/get-started/overview/#example-LucidLink-run-command
# - https://docs.LucidLink.com/engine/reference/commandline/run/

#     > LucidLink run --interactive --tty ubuntu /bin/bash
#     > LucidLink run -i -t ubuntu /bin/bash     # abbr


#     > LucidLink pull ubuntu            # implicitly runs
#     > LucidLink container create
# '@

    )
    # | Sort-Object 'ListItemText' -Unique
    | Sort-Object 'CompletionText' -Unique
    | __SortIt.WithoutPrefix 'ListItemText'
}
class LucidLogNameCompleter : IArgumentCompleter {

    # hidden [hashtable]$Options = @{
        # CompleteAs = 'Name'
    # }
    # hidden [string]$CompleteAs = 'Name'
    # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
    # LucidLogNameCompleter([int] $from, [int] $to, [int] $step) {
    LucidLogNameCompleter( ) { }
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

                # (Bintils.LucidLink.Parse.Logs -AsObject -infa Ignore).Keys | Sort-Object -Unique
                # | ?{ $_ -match $wordToComplete }
            ) | ?{
                 $_.ListItemText -match $WordToComplete
             }
        $found | ConvertTo-Json | Add-Content 'temp:\last.log' -ea 'continue'
        return $found
    }
}
class LucidLogNameCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [LucidLogNameCompletionsAttribute]::new()
        Pwsh> [LucidLogNameCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    [hashtable]$Options = @{}
    LucidLogNameCompletionsAttribute() { }

    [IArgumentCompleter] Create() {
        return [LucidLogNameCompleter]::new()
    }
}


class LucidLinkCompleter : IArgumentCompleter {

    # hidden [hashtable]$Options = @{
        # CompleteAs = 'Name'
    # }
    # hidden [string]$CompleteAs = 'Name'
    # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
    # LucidLinkCompleter([int] $from, [int] $to, [int] $step) {
    LucidLinkCompleter( ) {
        # $This.Options = @{
        #     # ExcludeDateTimeFormatInfoPatterns = $true
        #     CompleteAs = 'Name'
        # }

        # $this.Options
        #     | WriteJsonLog -Text '🚀 [LucidLinkCompleter]::ctor'
    }
    # LucidLinkCompleter( $options ) {
    # LucidLinkCompleter( $SomeParam = $false ) {
    LucidLinkCompleter( [string]$CompleteAs = 'Name'  ) {
        # $this.SomeParam = $SomeParam
        # $This.Options.CompleteAs = $CompleteAs
        # $This.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text '🚀 [LucidLinkCompleter]::ctor | SomeParam'

        # $PSCommandPath | Join-String -op 'not finished: Exclude property is not implemented yet,  ' | write-warning

        # $this.Options = $Options ?? @{}
        # $Options
            # | WriteJsonLog -Text '🚀 [LucidLinkCompleter]::ctor'
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
                __module.LucidLink.buildCompletions
            )
        return $found
    }

}

class LucidLinkCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [LucidLinkCompletionsAttribute]::new()
        Pwsh> [LucidLinkCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    [hashtable]$Options = @{}
    LucidLinkCompletionsAttribute() {
        # $this.Options = @{
        #     CompleteAs = 'Name'
        # }
        # $this.Options
        #     | WriteJsonLog -Text  '🚀LucidLinkCompletionsAttribute::new()'
    }
    LucidLinkCompletionsAttribute( [string]$CompleteAs = 'Name' ) {
        # $this.Options.CompleteAs = $CompleteAs
        # $this.Options
        #     | WriteJsonLog -Text  '🚀LucidLinkCompletionsAttribute::new | completeAs'
    }

    [IArgumentCompleter] Create() {
        # return [LucidLinkCompleter]::new($this.From, $this.To, $this.Step)
        # return [LucidLinkCompleter]::new( @{} )
        # '🚀LucidLinkCompletionsAttribute..Create()'
        #     | WriteJsonLog -PassThru
            # | .Log -Passthru
        # $This.Options
        #     | WriteJsonLog -PassThru

        return [LucidLinkCompleter]::new()
        # if( $This.Options.ExcludeDateTimeFormatInfoPatterns ) {
        #     return [LucidLinkCompleter]::new( @{
        #         ExcludeDateTimeFormatInfoPatterns = $This.Options.ExcludeDateTimeFormatInfoPatterns
        #     } )
        # } else {
        #     return [LucidLinkCompleter]::new()
        # }
    }
}
function Bintils.Debug.LucidLink.TestCompleter {
    'testing LucidLink completer....' | write-host -fg 'darkred' -bg 'gray20'
}

function Bintils.Invoke.LucidLinkWithCompletions {
    [Alias(
        'bin.Lucid',
        'b.LucidLink'
    )]
    param(
        [Parameter()]
        [LucidLinkCompletionsAttribute()]
        [string]$Commands
    )

    'invoking lucid nyi' | write-host -back 'magenta'
}

$scriptBlockNativeCompleter = {
    # param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    param($wordToComplete, $commandAst, $cursorPosition)
    [List[BintilsCompletionResult]]$items = @( __module.LucidLink.buildCompletions )



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
__module.LucidLink.OnInit
Register-ArgumentCompleter -CommandName 'Lucid' -Native -ScriptBlock $ScriptBlockNativeCompleter -Verbose

# note: Lc.* will export if you import this module directly
# but importing bintils itself, will not export
export-moduleMember -function @(
    'Lc.*'
    'LucidLink.*'
    'Bintils.LucidLink.*'
) -Alias @(
    'Lc.*'
    'LucidLink.*'
    'Bintils.LucidLink.*'
)
