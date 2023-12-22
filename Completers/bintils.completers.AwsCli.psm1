using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Collections.ObjectModel
# [Collections.ObjectModel.ReadOnlyCollection[CommandElementAst]]

$script:__moduleConfig = @{
    ExportPrefix_AwsCli = $true # export names that match: 'AwsCli.*'
    ExportPrefix_Aws = $true     # export names that match: 'Aws.*'
    VerboseJson_ArgCompletions = $true
    VerboseJson_ArgCompletionsLog = (Join-Path (gi 'temp:\') 'Bintils.Aws.ArgCompletions.log')
}
$script:awsCache = @{}

function Bintils.Aws.BuildBinArgs {
    <#
    .SYNOPSIS
        Builds arguments for native commands, by composing template names
    #>
    [Alias(
        'AwsCli.BuildBinArgs',
        'Aws.BuildBinArgs'
    )]
    [CmdletBinding()]
    param(
        # template[s] to build from
        [parameter()]
        [ArgumentCompletions(
            'aws',
            'ProfileBdg',
            'ProfileJake',
            's3',
            'AutoPrompt', 'No-AutoPrompt','NoAutoPrompt',
            'OutputYaml', 'OutputYamlStream',
            'OutputJson',
            'OutputText',
            'OutputTable',
            'DryRun',
            'help'
        )]
        [Alias('BaseTemplate')]
        [string[]]$Templates,

        [Alias('Prefix')]
        [object[]]$PrefixArgs,
        [Alias('Suffix')]
        [object[]]$AppendArgs,

        # [Alias('WhatIf')]
        # [switch]$DryRun,

        # write preview info stream
        [switch]$Preview
    )

    [List[object]]$binArgs = @()
    [List[Object]]$Prefix  = @()

    # initialize defaults for aws cli
    # $prefix.AddRange(@(
    #     '--no-cli-auto-prompt'))

    if($UsingWhatIf) {
         'Invoking Using -WhatIf / --dryrun mode'
             | write-host -fore 'yellow'
            $prefix.AddRange(@(
                '--dryrun'))
    }


    switch($Templates) {
        'aws' {
            $prefix.AddRange(@(
                'aws' ))
        }
        # 'rclone' {
        #     $prefix.AddRange(@(
        #         $BvAppConfig.BinRClone.FullName ))
                # 'G:\2023-git\git_bin\rclone-v1.64.2-windows-amd64\rclone.exe' ))
        # }
        'ProfileJake' {
            $prefix.AddRange(@(
                '--profile', 'jake'))
        }
        'ProfileBdg' {
            $prefix.AddRange(@(
                '--profile', 'BDG'))
        }
        'ColorOn' {
            $prefix.AddRange(@(
                '--color', 'on'))
        }
        'ColorOff' {
            $prefix.AddRange(@(
                '--color', 'off'))
        }
        'AutoPrompt' {
            $prefix.AddRange(@(
                '--cli-auto-prompt'))
        }
        's3' {
            $prefix.AddRange(@(
                's3'))
        }
        'help' {
            $prefix.AddRange(@(
                'help'))
        }
        'OutputYamlStream' {
            $prefix.AddRange(@(
                '--output', 'yaml-stream'))
        }
        'OutputYaml' {
            $prefix.AddRange(@(
                '--output', 'yaml'))
        }
        'OutputJson' {
            $prefix.AddRange(@(
                '--output', 'json'))
        }
        'OutputText' {
            $prefix.AddRange(@(
                '--output', 'text'))
        }
        'OutputTable' {
            $prefix.AddRange(@(
                '--output', 'table'))
        }
        { $_ -in @('NoAutoPrompt', 'No-AutoPrompt') } {
            # WithDry run, is now a no-op error
        }
        default {
            "Unhandled -Template name: '{0}'" -f ( $Switch -join ', ' )
            | write-error
            continue
        }
    }
    if($PrefixArgs.count -gt 0) {
        $binArgs.AddRange(@( $PrefixArgs))
    }

    $binArgs.AddRange(@(
        $prefix ))

    if($AppendArgs.count -gt 0) {
        $binArgs.AddRange(@( $AppendArgs))
    }

    # $script:Aws_LastBinArgs = $BinArgs

    if($Preview) {
        $binArgs | Bv.PreviewArgs
    }
    return $binArgs

    # $binArgs.AddRange(@(
    #     '--profile', 'jake'))

    # $binArgs.AddRange(@(
    #     's3' ))

    # $binArgs.AddRange(@(
    #     'ls' ))
}

function Bintils.Aws.Help {
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
function Bintils.Aws.GetConfigObject {
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

function New.Aws.CompletionResult {
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
        New.Aws.CompletionResult -Text 'CliAutoPrompt' -Replacement '--cli-auto-prompt' -ResultType ([CompletionResultType]::ParameterName) -Tooltip 'force prompt'
        New.Aws.CompletionResult -Text 'NoCliAutoPrompt' -Replacement '--no-cli-auto-prompt' -ResultType ParameterValue -Tooltip 'disable prompt, required for commands like docker login'
# '@
#         New.Aws.CompletionResult -Text 'Example.Run' -Replacement "run --interactive --tty ubuntu /bin/bash" -ResultType ParameterValue -Tooltip @'
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

class AwsProfileNameArgumentCompleter : IArgumentCompleter {
    <#
        it supports names with spaces
    #>
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $CommandName,
        [string] $ParameterName,
        [string] $WordToComplete,
        [CommandAst] $CommandAst,
        [IDictionary] $FakeBoundParameters
    ) {
        $state = $script:AwsCache
        [List[CompletionResult]]$Completions = @()
        <#
                [List[CompletionResult]]$found = @(
                $records = @( 'BDG', 'jake')
                    | Sort-Object -Unique | %{
                        New.AwsCR -ListItemText $_ -CompletionText $_ -ResultType ParameterValue -Tooltip "Aws ProfileName: 'aws config list-profile'"
                    }
            ) | ?{
                 $_.ListItemText -match $WordToComplete
             }
            # $found | ConvertTo-Json | Add-Content 'temp:\last.log' -ea 'continue'
            return $found
        #>
        if( -not ($state)?.ProfileNames ) {
            $state.ProfileNames = aws configure list-profiles  | Sort-object -Unique
        }

        $Completions = @(
            $state.ProfileNames | %{
                $Item         = $_
                $toMatch      = $_
                $toCompleteAs = $Item # Bintils.WhenContainsSpaces-FormatQuotes -Text $Item

                New.AwsCR -ListItemText $_ -CompletionText $_ -ResultType ParameterValue -Tooltip "Aws ProfileName: 'aws config list-profile'"
            }
        )

        if($Script:__ModuleConfig.VerboseJson_ArgCompletions) {
            $Completions
                | ConvertTo-Json
                | Add-Content $Script:__ModuleConfig.VerboseJson_ArgCompletionsLog -ea 'silentlycontinue'
        }

        # if( $script:__ModuleConfig.PrintExtraSummaryOnTabCompletion) {
        #     "`n" | write-host
        #     $Completions
        #         | format-table | out-string
        #         | write-host  #-bg $Script:Color.DimPurple
        #     "`n" | write-host
        # }
        return $Completions
    }
}
class AwsProfileNameCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
    <#
    .example
        Pwsh> [AwsProfileNameCompletionsAttribute]::new()
        Pwsh> [AwsProfileNameCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
    #>
    [hashtable]$Options = @{}
    AwsProfileNameCompletionsAttribute() { }

    [IArgumentCompleter] Create() {
        return [AwsProfileNameArgumentCompleter]::new()
    }
}


function Bintils.Aws.IAM.ListGroups {
    param(
        [Parameter()]
        $Profile

    )
}


# class AwsCompleter : IArgumentCompleter {

#     # hidden [hashtable]$Options = @{
#         # CompleteAs = 'Name'
#     # }
#     # hidden [string]$CompleteAs = 'Name'
#     # [bool]$ExcludeDateTimeFormatInfoPatterns = $false
#     # AwsCompleter([int] $from, [int] $to, [int] $step) {
#     AwsCompleter( ) {
#         # $This.Options = @{
#         #     # ExcludeDateTimeFormatInfoPatterns = $true
#         #     CompleteAs = 'Name'
#         # }

#         # $this.Options
#         #     | WriteJsonLog -Text '🚀 [AwsCompleter]::ctor'
#     }
#     # AwsCompleter( $options ) {
#     # AwsCompleter( $SomeParam = $false ) {
#     # AwsCompleter( [string]$CompleteAs = 'Name'  ) {
#         # $this.SomeParam = $SomeParam
#         # $This.Options.CompleteAs = $CompleteAs
#         # $This.CompleteAs = $CompleteAs
#         # $this.Options
#         #     | WriteJsonLog -Text '🚀 [AwsCompleter]::ctor | SomeParam'

#         # $PSCommandPath | Join-String -op 'not finished: Exclude property is not implemented yet,  ' | write-warning

#         # $this.Options = $Options ?? @{}
#         # $Options
#             # | WriteJsonLog -Text '🚀 [AwsCompleter]::ctor'
#         # if ($from -gt $to) {
#         #     throw [ArgumentOutOfRangeException]::new("from")
#         # }
#         # $this.From = $from
#         # $this.To = $to
#         # $this.Step = $step -lt 1 ? 1 : $step

#     # }
#     <#
#     .example

#     > try.Named.Fstr yyyy'-'MM'-'dd'T'HH':'mm':'ssZ
#     GitHub.DateTimeOffset  ShortDate (Default)    LongDate (Default)

#         Git Dto ⁞ 2023-11-11T18:58:42Z
#         yyyy'-'MM'-'dd'T'HH':'mm':'ssZ
#         Github DateTimeZone
#         Github DateTimeOffset UTC
#     #>

#     [IEnumerable[CompletionResult]] CompleteArgument(
#         [string] $CommandName,
#         [string] $parameterName,
#         [string] $wordToComplete,
#         [CommandAst] $commandAst,
#         [IDictionary] $fakeBoundParameters) {

#         # [List[CompletionResult]]$resultList = @()
#         # $DtNow = [datetime]::Now
#         # $DtoNow = [DateTimeOffset]::Now
#         # [bool]$NeverFilterResults = $false
#         # $Config = @{
#         #     # IncludeAllDateTimePatterns = $true
#         #     # IncludeFromDateTimeFormatInfo = $true
#         # }
#         # todo: pass query string filter
#         [List[CompletionResult]]$found = @(
#                 __module.Aws.buildCompletions
#             )
#         return $found
#     }

# }

# class AwsCompletionsAttribute : ArgumentCompleterAttribute, IArgumentCompleterFactory {
#     <#
#     .example
#         Pwsh> [AwsCompletionsAttribute]::new()
#         Pwsh> [AwsCompletionsAttribute]::new( CompleteAs = 'Name|Value' )
#     #>
#     [hashtable]$Options = @{}
#     AwsCompletionsAttribute() {
#         # $this.Options = @{
#         #     CompleteAs = 'Name'
#         # }
#         # $this.Options
#         #     | WriteJsonLog -Text  '🚀AwsCompletionsAttribute::new()'
#     }
#     AwsCompletionsAttribute( [string]$CompleteAs = 'Name' ) {
#         # $this.Options.CompleteAs = $CompleteAs
#         # $this.Options
#         #     | WriteJsonLog -Text  '🚀AwsCompletionsAttribute::new | completeAs'
#     }

#     [IArgumentCompleter] Create() {
#         # return [AwsCompleter]::new($this.From, $this.To, $this.Step)
#         # return [AwsCompleter]::new( @{} )
#         # '🚀AwsCompletionsAttribute..Create()'
#         #     | WriteJsonLog -PassThru
#             # | .Log -Passthru
#         # $This.Options
#         #     | WriteJsonLog -PassThru

#         return [AwsCompleter]::new()
#         # if( $This.Options.ExcludeDateTimeFormatInfoPatterns ) {
#         #     return [AwsCompleter]::new( @{
#         #         ExcludeDateTimeFormatInfoPatterns = $This.Options.ExcludeDateTimeFormatInfoPatterns
#         #     } )
#         # } else {
#         #     return [AwsCompleter]::new()
#         # }
#     }
# }

# $scriptBlockNativeCompleter = {
#     # param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
#     param($wordToComplete, $commandAst, $cursorPosition)
#     [List[AwsBintilsCompletionResult]]$items = @( __module.Aws.buildCompletions )

#     $FilterProp =
#         'ListItemText' # 'CompletionText'
#     [string]$parentName? = $commandAst.CommandElements
#         | Select -Last 1 | % value

#     $lastName = $commandAst.ToString() -split '\s+' | Select -last 1
#     $leftWord = $commandAst.CommandElements | Select -last 1



#     [List[Object]]$selected = @(
#         $items | ?{
#             [bool]$toKeep = (
#                 ( $_.ParentName -match [regex]::escape( $leftWord ) ) -or
#                     ( [string]::IsNullOrWhiteSpace( $_.ParentName ) ) -or
#                     ( $_.ParentName -eq 'lucid' ) -or
#                     [string]::IsNullOrWhiteSpace( $leftWord ) -or
#                     $false
#             )
#             return $toKeep
#         }
#     )
#         # | ?{
#         #     $matchesAny = (
#         #         $_.$FilterProp -match $WordToComplete -or
#         #         $_.$FilterProp -match [regex]::escape( $WordToComplete ) -or
#         #         # // or statically
#         #         $_.ListItemText -match $wordToComplete -or
#         #         $_.CompletionText -match $wordToComplete -or
#         #         $_.ListItemText -match [regex]::escape( $wordToComplete ) -or
#         #         $_.CompletionText -match [regex]::escape( $wordToComplete ) )

#         #     return $MatchesAny
#         # }


#     if('based on heirarchy') {
#         $crumbs = $commandAst.CommandElements.Value
#     }

#     if('VerboseLoggingState') {
#         $PSStyle.OutputRendering = 'PlainText'

#         @(
#             "`n ===== Lucid native completion result ==== "
#             get-date
#             $PSCommandPath |Join-String -op 'source: '
#             [ordered]@{
#                 'Left' = $LeftWord
#                 'Command' = $PSCommandPath
#                 'Word' = $WordToComplete
#                 'Cursor' = $cursorPosition
#                 'last' = $commandAst.CommandElements[-1]
#                 'last2' = $commandAst.CommandElements[-2]

#             } | Ft -auto | out-String
#             $commandAst | Bintils.Common.Format.CommandAst
#             "`n"
#             "`n"
#             $commandAst|ft -AutoSize | Out-string
#             $commandAst|fl | Out-string
#             "`n"
#         )
#         | Add-Content -Path 'temp:\completers.log'
#         $PSStyle.OutputRendering = 'Ansi'

#     }
#     $final_CE = [List[CompletionResult]]@( $selected.ToCompletion() ) # should declare an auto coercable  class
#     if($final_CE.Count -eq 0){
#         [string]$render_tooltip = @(
#             # 'Special 0 matches found, tooltip'
#             # Join-String -f 'Word: {0}' -in $wordToComplete
#             # $commandAst | JOin-String -sep ', ' { $_.ToString() }
#             # Join-String -op 'cusor pos' -In $cursorPosition
#             'special 0 results, fallback completer'
#         ) | Join-String -sep "`n"

#         $final_CE.add(
#             [CompletionResult]::new(
#                 <# completionText: #> 'help',
#                 <# listItemText: #> '--help',
#                 <# resultType: #> [CompletionResultType]::ParameterValue,
#                 <# toolTip: #> $render_tooltip)
#         )
#     }

#     return $final_CE
# }

function __module.Aws.OnInit {
    param()
    'Bintils.Aws::Init' | write-verbose -Verbose
    # gcm 'AwsCli*'
    # gcm 'Aws.*'
    # gcm -m bintils.completers.AwsCli
}

# note: Aws.* will export if you import this module directly
# but importing bintils itself, will not export
export-moduleMember -function @(
    if($__moduleConfig.ExportPrefix_Cli) {
        'Aws.*'
        'Bintils.Aws.*'
    }
    if($__moduleConfig.ExportPrefix_AwsCli) {
        'AwsCli.*'
        'Bintils.AwsCli.*'
    }
) -Alias @(
    if($__moduleConfig.ExportPrefix_Cli) {
        'Aws.*'
        'Bintils.Aws.*'
    }
    if($__moduleConfig.ExportPrefix_AwsCli) {
        'AwsCli.*'
        'Bintils.AwsCli.*'
    }
)

# Register-ArgumentCompleter -CommandName 'AwsCli' -Native -ScriptBlock $ScriptBlockNativeCompleter -Verbose

__module.Aws.OnInit
