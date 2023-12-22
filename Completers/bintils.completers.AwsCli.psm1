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
            # write-warning 'build bin args here: AwsNameCompelter'
            $state.ProfileNames = aws configure list-profiles --no-cli-auto-prompt | Sort-object -Unique
                # aws configure list-profiles
        }

        $Completions = @(
            $state.ProfileNames | %{
                $Item         = $_
                $toMatch      = $_
                $toCompleteAs = $Item # Bintils.WhenContainsSpaces-FormatQuotes -Text $Item
                New.Aws.CompletionResult -ListItemText $_ -CompletionText $_ -ResultType ParameterValue -Tooltip "Aws ProfileName: 'aws config list-profile'"
            } | %{
                $_.ToCompletion()
            }
            |?{
                $_.ListItemText -match [regex]::escape( $WordToComplete )
            }
        )

        if($Script:__ModuleConfig.VerboseJson_ArgCompletions) {
            $Completions
                | ConvertTo-Json
                | Add-Content $Script:__ModuleConfig.VerboseJson_ArgCompletionsLog #ea 'silentlycontinue'
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
    [Alias(
        'Aws.IAM.ListGroups'
    )]
    param(
        [Parameter()]
        [AwsProfileNameCompletionsAttribute()]
        $Profile
    )

}

function __module.Aws.OnInit {
    param()
    'Bintils.Aws::Init' | write-verbose -Verbose
    if( $script:__moduleConfig.VerboseJson_ArgCompletions) {
        'Bintils.Aws::Init: Enabled Completions logging to {0}' -f @(
            $script:__moduleConfig.VerboseJson_ArgCompletionsLog
        ) | Write-verbose -verbose
    }
    # gcm 'AwsCli*'
    # gcm 'Aws.*'
    # gcm -m bintils.completers.AwsCli
}

# note: Aws.* will export if you import this module directly
# but importing bintils itself, will not export
export-moduleMember -function @(

    if($__moduleConfig.ExportPrefix_Aws) {
        'Aws.*'
        'Bintils.Aws.*'
    }
    if($__moduleConfig.ExportPrefix_AwsCli) {
        'AwsCli.*'
        'Bintils.AwsCli.*'
    }
) -Alias @(
    if($__moduleConfig.ExportPrefix_Aws) {
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
