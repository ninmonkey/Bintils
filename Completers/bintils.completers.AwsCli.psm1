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


function aws.Write-Information {
    <#
    .SYNOPSIS
        sugar for : obj | Write-information -infa 'continue'
    #>
    [Alias('aws.Infa')]  ##>, 'wInfo', 'Infa', 'Write.Infa')]
    param(
        [switch]$WithoutInfaContinue
    )
    if($WithoutInfaContinue) {
        $Input | Write-Information
        return
    }
    $Input | Write-Information -infa 'continue'
}
function Aws.Write-DimText {
    <#
    .SYNOPSIS
        # sugar for dim gray text,
    .EXAMPLE
        # pipes to 'less', nothing to console on close
        get-date | Dotils.Write-DimText | less

        # nothing pipes to 'less', text to console
        get-date | Dotils.Write-DimText -PSHost | less
    .EXAMPLE
        > gci -Name | Dotils.Write-DimText |  Join.UL
        > 'a'..'e' | Dotils.Write-DimText  |  Join.UL
    #>
    [OutputType('String')]
    [Alias('DimText', 'aws.DimText')]
    param(
        # write host explicitly
        # [switch]$PSHost
    )
    $ColorDefault = @{
        ForegroundColor = '#515151' # 'gray60'
        BackgroundColor = '#999999'  # 'gray20'
    }
    $renderColor = @(
        $PSStyle.Foreground.FromRgb( $ColorDefault.ForegroundColor )
        $PSStyle.Background.FromRgb( $ColorDefault.BackgroundColor )
    ) -join ''

    return $Input
        | Join-String -op $renderColor -os $PSStyle.Reset
        # | New-Text @colorDefault
        # | % ToString
}
[int]$script:__historyNextId = 0

class HistoryRecord {
    [datetime]$When
    [int]$Order
    [List[Object]]$CommandLine = @()
    [List[Object]]$Results     = @()
    HistoryRecord () {
        $This.When = [Datetime]::Now
        $this.Order = ($script:__historyNextId)++
    }
}

[List[HistoryRecord]]$script:AwsHistory = @()
function Aws.InvokeBin {
    <#
    .SYNOPSIS
        Actually calls the native command, and waits fora a confirm prompt. Args may come from Bv.BuildBinArgs
    #>
    # [Alias('Aws.InvokeBin')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Low')]
    param(
        [object[]]$BinArgs,

        # do not write to info stream, or at least not explicit
        [switch]$Silent

        # [ArgumentCompletions('aws', 'rclone')]
        # [Alias('NativeCommandName')]
        # [string]$CommandName = 'aws'
    )
    $Config = @{
        VerboseOutput = $false
    }
    $CommandName = 'Aws'
    if($Config.VerboseOutput) {
        'Invoke: ' | write-verbose -Verbose
    # "`n`n"
        $BinArgs | Aws.PreviewArgs
    }
    $binAws = Get-Command -CommandType Application -Name $CommandName -TotalCount 1 -ea 'stop'
    # "`n`n"
    # "`n`n"
    if ($PSCmdlet.ShouldProcess(
        "$( $BinArgs -join ' '  )",
        "Bv.InvokeBin: $( $CommandName )")
    ) {
        if($Config.VerboseOutput) {
            '   Calling "{0}"' -f @( $CommandName )
                | write-host -fore 'green'

            '   Calling "{0}"' -f @( $CommandName )
            # '::invoke: => Confirmed'
                | Aws.Write-DimText | Write-Information #-infa 'continue'
            }
        $result = & $BinAws @BinArgs
        $history = [HistoryRecord]@{
            Results     = $result
            CommandLine = $BinArgs
        }
        $script:AwsHistory.add( $history )
    } else {
        # '::invoke: => Skip' | Aws.Write-DimText | Write-Information -infa 'continue'
        '   Skipped calling "{0}"' -f @( $CommandName ) | write-host -back 'darkred'
    }
    if( $Silent ) { return }
    $BinArgs | Aws.PreviewArgs
        # | write-host -fore 'Green'
}
function Aws.PreviewArgs {
    <#
    .SYNOPSIS
        write dim previews of the args
    #>
    # param( [object[]]$InputObject )
    $Input
        | Join-String -sep ' ' -op 'bin args => @( ' -os ' )'
        | Aws.Write-DimText
        | aws.Infa
}


function Bintils.Aws.BuildBinArgs {
    <#
    .SYNOPSIS
        Builds arguments for native commands, by composing template names
    .example
        Aws.InvokeBin -BinArgs ( Aws.BuildBinArgs -Templates NoCliAutoPrompt, SkeletonYaml -PrefixArgs 'iam')
    #>
    [Alias(
        'AwsCli.BuildBinArgs',
        'Aws.BuildBinArgs'
    )]
    [CmdletBinding()]
    param(
        # template[s] to build from
        # future: this would auto complete based on metadata
        [parameter()]
        [ArgumentCompletions(
            'ProfileJake',
            'CliAutoPrompt', 'No-CliAutoPrompt','NoCliAutoPrompt',
            'Skeleton', 'SkeletonYaml',

            # outputkinds
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

        [Alias('Args', 'ArgList')]
        [Alias('Suffix')]
        [object[]]$AppendArgs,

        # [Alias('WhatIf')]
        # [switch]$DryRun,

        # write preview info stream
        [switch]$Preview
    )
    [List[Object]]$paramTemplates = @( $Templates )
    [List[object]]$binArgs = @()
    [List[Object]]$PrefixArgs = @( $PrefixArgs)

    # initialize noprompt as defaults for aws cli, because many commands break piping if enabled
    # $defines_AutoPrompt = (@( $Templates ) -match '(No)?.*CliAutoPrompt' ).count -gt 0
    # if( -not $defines_AutoPrompt ) { $binArgs.add( '--no-cli-auto-prompt') }

    # if( -not $defines_Autoprompt) { $binArgs.AddRange(@( '--no-cli-auto-prompt')) }


    # if( -not $Templates )
    # $prefix.AddRange(@(
    #     '--no-cli-auto-prompt'))

    # if($UsingWhatIf) {
    #      'Invoking Using -WhatIf / --dryrun mode'
    #          | write-host -fore 'yellow'
    #         $prefix.AddRange(@(
    #             '--dryrun'))
    # }



    switch($Templates) {
        'Skeleton' {
            $binArgs.AddRange(@(
                '--generate-cli-skeleton'
            ))
        }
        'SkeletonYaml' {
            $binArgs.AddRange(@(
                '--generate-cli-skeleton', 'yaml-input'
            ))
        }
        'ProfileJake' {
            $binArgs.AddRange(@(
                '--profile', 'jake'))
        }
        'ColorOn' {
            $binArgs.AddRange(@(
                '--color', 'on'))
        }
        'ColorOff' {
            $binArgs.AddRange(@(
                '--color', 'off'))
        }
        'CliAutoPrompt' {
            $binArgs.AddRange(@(
                '--cli-auto-prompt'))
        }
        'NoCliAutoPrompt' {
            $binArgs.AddRange(@(
                '--no-cli-auto-prompt'))
        }
        'OutputYamlStream' {
            $binArgs.AddRange(@(
                '--output', 'yaml-stream'))
        }
        'OutputYaml' {
            $binArgs.AddRange(@(
                '--output', 'yaml'))
        }
        'OutputJson' {
            $binArgs.AddRange(@(
                '--output', 'json'))
        }
        'OutputText' {
            $binArgs.AddRange(@(
                '--output', 'text'))
        }
        'OutputTable' {
            $binArgs.AddRange(@(
                '--output', 'table'))
        }
        # { $_ -in @('NoAutoPrompt', 'No-AutoPrompt') } {
            # WithDry run, is now a no-op error
        # }
        '' {
            if (-not $PSBoundParameters.ContainsKey( 'Template' ) ) { continue }
            write-warning 'blankable template passed'
        }
        default {
            "Unhandled -Template name: '{0}'" -f ( $Switch -join ', ' )
            | write-error
            continue
        }
    }

    if( $BinArgs.Contains('--no-cli-auto-prompt') -and $BinArgs.Contains('--cli-auto-prompt') ) {
        throw "InvalidParametersException: Cannot use both args at once: --[no-]cli-auto-promp"
    }
    if( $paramTemplates.Contains('ColorOn') -and $paramTemplates.Contains('ColorOn') ) {
        throw "InvalidParametersException: Cannot use both args at once: ColorOn, ColorOff"
    }

    $binArgs = @(
        $PrefixArgs
        $BinArgs
        $AppendArgs
    )
    $defines_Autoprompt = -not $binArgs.Exists({ $_ -in @( '--no-cli-auto-prompt', '--cli-auto-prompt'  ) })
    if( -not $defines_Autoprompt ) {
        $binArgs.AddRange(@('--no-cli-auto-prompt'))
    }

    $outputTemplateNames = 'OutputYamlStream', 'OutputYaml', 'OutputJson', 'OutputText', 'OutputTable'
    if( ($BinArgs.Where({$_ -in @($OutputTemplateNames) }) ).count -gt 1 ) {
        throw ('Multiple instances of OutputFormats were used!: Templates = @( {0} )' -f @(
            $Templates -join ', '
        ))
    }
    # vaidation: future, check for parameter '--output', then get the index of the next, and see if it's valid
    # then check if 'output' matches any cases were index previous is not --output


    # $script:Aws_LastBinArgs = $BinArgs

    if($Preview) {
        $binArgs | Aws.PreviewArgs
    }
    return $binArgs

    # $binArgs.AddRange(@(
    #     '--profile', 'jake'))

    # $binArgs.AddRange(@(
    #     's3' ))

    # $binArgs.AddRange(@(
    #     'ls' ))
}
function Bintils.Aws.GenerateSkeleton {
    <#
    .SYNOPSIS
    .EXAMPLE
        # original
        aws iam list-groups --no-cli-auto-prompt --generate-cli-skeleton
    .EXAMPLE
        Aws.GenerateSkeleton -Commands 'iam', 'list-groups' Yaml
        Aws.GenerateSkeleton -Commands 'iam', 'list-groups' Json
    .EXAMPLE
        Aws.GenerateSkeleton -Commands 'iam', 'list-groups' Json -PageColor

    #>
    [Alias('Aws.GenerateSkeleton')]
    param(
        [Parameter(Mandatory)]
        [string[]]$Commands,

        [Parameter()]
        [ArgumentCompletions('Json', 'Yaml')]
        [string]$Format = 'Json',

        [Alias('PassThru', 'NoColor')]
        [switch]$WithoutColor
    )
    if($Format -eq 'Yaml') {
        $binArgs = Bintils.Aws.BuildBinArgs -Templates NoCliAutoPrompt, SkeletonYaml -PrefixArgs $Commands -Preview:$false
    } else {
        $binArgs = Bintils.Aws.BuildBinArgs -Templates NoCliAutoPrompt, Skeleton -PrefixArgs $Commands -Preview:$false
    }
    if( $WithoutColor ) {
        Aws.InvokeBin -binArgs $BinArgs
        return
    }
    $lang = $Format -eq 'Json' ? 'json' : 'yml'
    Aws.InvokeBin -binArgs $BinArgs | bat --language $Lang --force-colorization
}
function Bintils.Aws.Help {
    [Alias('Aws.Help')]
    [CmdletBinding()]
    param()

    $docRecord = @{ TopicName = 'AwsCli_Reference'
        Description = 'top-level AwsCli reference' }
    $DocRecord.Contents = @( @"

AwsVersion: $(aws --version)

- [Troubleshooting docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html)
- [cli skeleton](https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-skeleton.html): Most of the AWS Command Line Interface (AWS CLI) commands accept all parameter inputs from a file. These templates can be generated using the generate-cli-skeleton option

Example invoke:

    > Aws.GenerateSkeleton -Commands 'iam', 'list-groups' Yaml | bat -l yaml

***************

The AWS CLI has a few general options:

+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| Variable             | Option         | Config Entry          | Environment Variable  | Description                      |
+======================+================+=======================+=======================+==================================+
| profile              | --profile      | N/A                   | AWS_PROFILE           | Default profile name             |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| region               | --region       | region                | AWS_DEFAULT_REGION    | Default AWS Region               |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| output               | --output       | output                | AWS_DEFAULT_OUTPUT    | Default output style             |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| cli_timestamp_format | N/A            | cli_timestamp_format  | N/A                   | Output format of timestamps      |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| ca_bundle            | --ca-bundle    | ca_bundle             | AWS_CA_BUNDLE         | CA Certificate Bundle            |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| parameter_validation | N/A            | parameter_validation  | N/A                   | Toggles parameter validation     |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| tcp_keepalive        | N/A            | tcp_keepalive         | N/A                   | Toggles TCP Keep-Alive           |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| max_attempts         | N/A            | max_attempts          | AWS_MAX_ATTEMPTS      | Number of total requests         |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| retry_mode           | N/A            | retry_mode            | AWS_RETRY_MODE        | Type of retries performed        |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+
| cli_pager            | --no-cli-pager | cli_pager             | AWS_PAGER             | Redirect/Disable output to pager |
+----------------------+----------------+-----------------------+-----------------------+----------------------------------+

Pager
=====

The AWS CLI uses a pager for output data that does not fit on the
screen.

On Linux/MacOS, "less" is used as the default pager. On Windows, the
default is "more".


Configuring pager
-----------------

You can override the default pager with the following configuration
options. These are in order of precedence:

* "AWS_PAGER" environment variable

* "cli_pager" shared config variable

* "PAGER" environment variable

If you set any of the configuration options to an empty string (e.g.
"AWS_PAGER=""") or use "--no-cli-pager" option in the command line the
AWS CLI will not send the output to a pager.


Examples
~~~~~~~~

To disable the pager for "default" profile:

   aws configure set cli_pager "" --profile default

To disable the pager for all profiles in the current terminal session:

   export AWS_PAGER="" - for Linux

   set AWS_PAGER="" - for Windows cmd

To disable the pager for one command call:

   aws <command> <sub-command> --no-cli-pager


Pager settings
--------------

If the "LESS" environment variable is not set the AWS CLI will set it
to "FRX" (see "less" manual page for more information about possible
options https://man7.org/linux/man-pages/man1/less.1.html) in order to
set the appropriate flags. If you set the "LESS" env var, we will not
clobber it with ours (e.g. "FRX"). Be aware that different shells can
have different default values for the "LESS" environment variable that
can cause unexpected behavior of AWS CLI output

You can also set flags when specifying the pager and those will
combine with any environment variables we set (e.g. "AWS_PAGER="less
-S"" will make it less "-FRXS"). The behavior of combining flags is a
feature of "less". You can also negate flags we set by specifying it
on the command line: (e.g. "AWS_PAGER="less -+F"" will deactivate the
quit if one screen behavior)

For Windows, "more" is used with no additional environment variables.

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
        if( -not ($state)?.ProfileNames ) {
            $state.ProfileNames = Aws.InvokeBin (
                    Aws.BuildBinArgs -Preview:$false -Templates NoCliAutoPrompt -AppendArgs 'configure', 'list-profiles' )
                        | Sort-object -Unique

        }

        $Completions = @(
            $state.ProfileNames | %{
                if( [String]::IsNullOrEmpty( $Item )) { return } # ListItem blank will throw
                $Item         = $_
                $toMatch      = $Item
                $toCompleteAs = $Item # Bintils.WhenContainsSpaces-FormatQuotes -Text $Item
                New.Aws.CompletionResult -ListItemText $Item -CompletionText $toCompleteAs -ResultType ParameterValue -Tooltip "Aws ProfileName: 'aws config list-profile'"
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
        [Parameter(Mandatory)]
        [AwsProfileNameCompletionsAttribute()]
        $Profile,

        [Alias('AsJson', 'RawJson')][switch]$PassThru
    )
    # write-debug 'future: auto cache web requests'
    'Profile: {0}' -f $Profile | Write-verbose

    if( $PassThru) {
        $binArgs = Aws.BuildBinArgs -Templates NoCliAutoPrompt, OutputJson -Args 'iam', 'list-groups', '--profile', $Profile
        $response = Aws.InvokeBin -BinArgs $binArgs
        ( $Response| COnvertFrom-Json ).Groups
        return
    }

    $binArgs = Aws.BuildBinArgs -Templates NoCliAutoPrompt -Args 'iam', 'list-groups', '--profile', $Profile
    $response = Aws.InvokeBin -BinArgs $binArgs
    return $response
    # aws iam get-user --output table
    # aws iam list-groups --generate-cli-skeleton
    # $json = Internal.GetCachedValue -keyName 'aws.IAM.GetGroups' -SilentError
    # if( -not $Json ) {
    #     $json = aws iam list-groups --no-cli-auto-prompt
    #     Internal.SetCachedValue -keyName 'aws.IAM.GetGroups' -Value $Json
    # # }
    # 'aws iam list-groups --no-cli-auto-prompt'
    #     | di.DimText | di.Infa

    # $json = aws iam list-groups --profile $ProfileName --output $OutputFormat --no-cli-auto-prompt


    # # $json = aws iam list-groups --no-cli-auto-prompt
    # if($PassThru) { return $Json }

    # if($OutputFormat -eq 'json') {
    #     $Json | ConvertFrom-Json | % Groups
    # } else {
    #     $Json
    # }
    # return

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
) -Variable @(
    'AwsHistory'
    'Aws*'
)

# Register-ArgumentCompleter -CommandName 'AwsCli' -Native -ScriptBlock $ScriptBlockNativeCompleter -Verbose

__module.Aws.OnInit
