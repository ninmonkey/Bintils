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
function Bintils.Docker.Help {
    [CmdletBinding()]
    param()

    $docRecord = @{ TopicName = 'Dockerfile_Reference'
        Description = 'top-level Dockerfile reference' }
    $DocRecord.Contents = @( @'

- https://docs.docker.com/engine/reference/builder/


tips:
- [using docker build cache](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache)
- on windows it *can* make sense to [set escape to backtick, rational here](https://docs.docker.com/engine/reference/builder/#escape)


'@ )
    $DocRecord.Contents | Join-String -sep "`n" | Write-information -infa 'Continue'
    return [pscustomobject]$docRecord
}
function Bintils.Docker.Logs {
    param(
        # --changed-within 20minutes
        [ArgumentCompletions(
            '10minutes', '5minutes',
            '90seconds',
            '2days',
            '2hours',
            '90minutes',
            '20minutes'
        )]
        [string]$SinceTime
    )
    @'
    'see:
        https://docs.docker.com/config/daemon/logs/
        https://docs.docker.com/config/containers/logging/
        https://docs.docker.com/config/containers/logging/configure/
            run -it log driver mode'

try
    > fd --search-path (gi (Join-Path $Env:LocalAppData 'Docker'))
'@
    | write-host

    Join-Path $Env:LocalAppData 'Docker'
    [List[Object]]$binArgs = @(
        '--search-path'
        (gi (Join-Path $Env:LocalAppData 'Docker') -ea 'stop')
        '-tf'
        if($SinceTime) {
            '--changed-within'
            $SinceTime
        }
    )
    # fd --search-path (gi (Join-Path $Env:LocalAppData 'Docker')) -tf --changed-within 20minutes | gi | % Extension | group -NoElement | % Name | Join-string -sep ', ' -op 'extensions found: ' | write-host -fg 'darkyellow'


    $binArgs | Join-String -sep ' ' -op 'fd args => ' | write-verbose -verb
    & fd @binArgs
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

function Bintils.Docker.SBom {
    <#
    .SYNOPSIS
        (experimental plugin) View the packaged-based Software Bill Of Materials (SBOM) for an image.
    .NOTES
    Usage:  docker sbom [OPTIONS] COMMAND

    View the packaged-based Software Bill Of Materials (SBOM) for an image.

    EXPERIMENTAL: The flags and outputs of this command may change. Leave feedback on https://github.com/docker/sbom-cli-plugin.

    Examples:

    docker sbom alpine:latest                                          a summary of discovered packages
    docker sbom alpine:latest --format syft-json                       show all possible cataloging details
    docker sbom alpine:latest --output sbom.txt                        write report output to a file
    docker sbom alpine:latest --exclude /lib  --exclude '**/*.db'      ignore one or more paths/globs in the image


    Options:
    -D, --debug                 show debug logging
        --exclude stringArray   exclude paths from being scanned using a
                                glob expression
        --format string         report output format, options=[syft-json
                                cyclonedx-xml cyclonedx-json github-0-json
                                spdx-tag-value spdx-json table text]
                                (default "table")
        --layers string         [experimental] selection of layers to
                                catalog, options=[squashed all] (default
                                "squashed")
    -o, --output string         file to write the default report output to
                                (default is STDOUT)
        --platform string       an optional platform specifier for
                                container image sources (e.g.
                                'linux/arm64', 'linux/arm64/v8', 'arm64',
                                'linux')
        --quiet                 suppress all non-report output
    -v, --version               version for sbom

    Commands:
    version     Show Docker sbom version information
    .LINK
        https://github.com/docker/sbom-cli-plugin
    #>
    [CmdletBinding()]
    param(
        [ArgumentCompletions(
            'alpine:latest')]
        [string]$Target,

        # which json/xml variant to use, or txt tables? := 'cyclonedx-json', 'cyclonedx-xml', 'github-0-json', 'spdx-json', 'spdx-tag-value', 'syft-json', 'table', 'text'
        [Parameter()]
            [Alias('Format','ExportAs')]
            [ArgumentCompletions(
                'syft-json', 'cyclonedx-xml', 'cyclonedx-json', 'github-0-json',
                'spdx-tag-value', 'spdx-json', 'table', 'text'
            )]
            [string]$OutputFormat = 'table',


        #  [experimental] selection of layers to catalog, options=[squashed all] (default "squashed")
        [Parameter()]
            [ArgumentCompletions('squashed', 'all')]
            [string]$LayersExperimental,

        [string]$Path,

        # an optional platform specifier for container image sources (e.g. 'linux/arm64', 'linux/arm64/v8', 'arm64', 'linux')
        [Parameter()]
        [string]$Platform,

        [Alias('Silent')][switch]$Quiet,
        [switch]$Version,

        [Alias('Log', 'WithLogging', 'WithVerbose')]
        [switch]$DebugLog,

        #  ex: --exclude /lib  --exclude '**/*.db'
        [ArgumentCompletions(
            '/lib', '**/*.db'
        )]
        [string[]]$Excludes

    )
    [List[Object]]$BinArgs = @(
        'sbom'
        $Target
        if( $DebugLog ) { '--debug' }
        if($OutputFormat) {
            '--format'
            $OutputFormat
        }
        if($Path) {
            '--output'
            $Path
        }
        if($PlatForm) { '--platform' ; $Platform }
        if( $Quiet ) { '--quiet' }
        if( $Version ) { '--version' }
        foreach($Glob in $Excludes) {
            '--exclude'
            $Glob
        }
    )
    $BinArgs |Join-String -sep ' ' -op 'invoking docker Bom => ' | Write-Verbose -verb
    # todo: should be using build template and auto log native commands
    & docker @binArgs
}
class NamedLocations {
    [string]$Name
    [string]$Group
    [string]$Description
    [object]$Path
}

function Bintils.Docker.Config.FindLocations {
    <#
    .SYNOPSIS
        find misc docker config locations
    .example
         Bintils.Docker.Config.FindLocations
    .link
        https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file
    .notes

        C:\Program Files\Docker\Docker\resources
    #>
    [Alias('Bintils.Docker.DockerD.Config.FindLocations')]
    [OutputType([NamedLocations])]
    [CmdletBinding()]
    param()

    [List[NamedLocations]]$Locations = @(
        # [NamedLocations]@{
        #     Name =
        # }
    )

@'
- searching paths:

    /etc/docker/daemon.json
    C:\Program Files' 'Docker'
    $Env:ProgramData 'docker/config/daemon.json'
'@ | Join-String -sep "`n" -op (Join-String -f "from {0} =>`n" -in $MyInvocation.MyCommand.Name)
    | write-verbose

    if($IsWindows) {

            'C:\Program Files\Docker\Docker\'
        $locations.Add( [NamedLocations]@{
                Name = 'linux-daemon-options.json (ProgramFiles)'
                Description = 'app.json'
                Group = 'Static.Manually.Added'
                Path = (Join-path $env:ProgramFiles 'Docker/Docker/resources/linux-daemon-options.json')
            })
        $locations.Add( [NamedLocations]@{
                Name = 'app.json (ProgramFiles)'
                Description = 'app.json. https://github.com/docker/cli/blob/master/cli/config/configfile/file.go'
                Group = 'Static.Manually.Added'
                Path = (Join-path $env:ProgramFiles 'Docker/Docker/app.json')
            })
        $locations.Add( [NamedLocations]@{
                Name = 'config-options.json (ProgramFiles)'
                Description = 'config-options.json. https://github.com/docker/cli/blob/master/cli/config/configfile/file.go'
                Group = 'Static.Manually.Added'
                Path = (Join-path $env:ProgramFiles 'Docker/Docker/resources/config-options.json')
            })

    }


    if($IsWindows) {
        gci -Path (gi 'C:\Program Files\Docker\Docker') *.json -Recurse
            | ? FullName -notmatch '\bfrontend\b'
            | %{
                $locations.Add( [NamedLocations]@{
                    Name = $_.Name
                    Description = 'Found under: C:/Program Files/Docker/Docker'
                    Group = 'Misc Json'
                    Path = $_.FullName | Get-Item
                })
            }
    }

    # hidden/system files may require -force to find
    $daemonJson? =
        if ($IsLinux) {
            Get-Item -Force -ea 'silentlycontinue' '/etc/docker/daemon.json'}
        elseif ($IsWindows) {
            Get-Item -Force -ea 'silentlycontinue' (
                Join-Path  $Env:ProgramData 'docker/config/daemon.json') }

    $Locations.Add( [NamedLocations]@{
        Name = 'daemon.json'
        Description = 'default daemon.json location'
        Group = 'Config'
        Path = $daemonJson? ?? "`u{2400}"
    })


    # fd -e json --search-path (gi (Join-Path $env:AppData 'Docker'))
    gci (gi (Join-Path 'C:\Program Files' 'Docker')) -Filter *.json -Recurse | %{
        $Locations.Add( [NamedLocations]@{
            Name = $_.Name
            Description = 'Found under: C:/Program Files/Docker'
            Group = 'Misc Json'
            Path = $_.FullName | Get-Item
        })
    }
    gci (gi (Join-Path $env:AppData 'Docker')) -Filter *.json -Recurse | %{
        $Locations.Add( [NamedLocations]@{
            Name = $_.Name
            Description = 'Found under: $Env:AppData/Docker'
            Group = 'Config'
            Path = $_.FullName | Get-Item
        })
    }
    return $locations
}
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

function Bintils.Docker.NewTemplateString {
    <#
    .SYNOPSIS
    .notes
        See Formatting functions: https://docs.docker.com/config/formatting/
        # table specifies which fields you want to see its output.
        > docker inspect --format '{{join .Args " , "}}' container

        # json encode values
        > docker inspect --format '{{json .Mounts}}' container

        # join and split
        # split slices a string into a list of strings separated by a separator.
        > docker inspect --format '{{join .Args " , "}}' container
        > docker inspect --format '{{split .Image ":"}}' container

        # lower/title cases
        > docker inspect --format "{{lower .Name}}" container
        > docker inspect --format "{{title .Name}}" container
    .EXAMPLE
        docker inspect $containerName (Bintils.Docker.NewTemplateString Json.All)
    .link
        https://docs.docker.com/config/formatting/
    #>
    param(
        [ValidateSet(
            'Hint',
            'Json.All',
            'Json.Dot',
            'Join.Args'
        )]
        [string]$TemplateName = 'Hint',
        [switch]$AutoEscapeDoubleQuotes
    )
    [string]$Template = ''
    if(-not $PSBoundParameters.ContainsKey('AutoEscapeDoubleQuotes') ) {
        if( $IsWindows ) { $AutoEscapeDoubleQuotes = $true }
        else { $AutoEscapeDoubleQuotes = $false}
    }

    switch($TemplateName) {
        { $_ -in @('Hint', 'Json.All')} {
            $template = @'
--format='{{json .}}'
'@
            break
        }
        'JoinArgs' {
            # join concatenates a list of strings to create a single string. It puts a separator between each element in the list.
            $template = '{{join .Args " , "}}'
        }
        default {
            throw "Unhandled TemplateName for NewTemplateFormatString: $TemplateName"
        }
    }
    if($AutoEscapeDoubleQuotes) {
        $template = $template -replace '"', '\"'
    }
    return $template
}

function Bintils.Docker.PipeJson {
    <#
    .synopsis
        Sometimes json comes back as quoted, 
    #>
    param(
        [string[]]$Lines
    )
    docker inspect $containerName (Bintils.Docker.NewTemplateString Json.All)
}

function Bintils.Docker.Inspect {
    param(
        [ValidateNotNullOrWhitespace()]
        [string]$ContainerName,

        # return as the original, text document rather than objects
        [Alias('AsText', 'AsJson')]
        [switch]$PassThru
    )

    [List[Object]]$binArgs = @(
        'inspect'
        $ContainerName
    )

    $result = & docker @binArgs
    if( $PassThru ) { return $result  }

    $result | Json.From
    return
}
function Bintils.Docker.Parse.Containers.Get {
    <#
    .SYNOPSIS
        parse docker containers command
    .EXAMPLE
        Pwsh> Bintils.Docker.Parse.Containers
    .EXAMPLE
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
    [Alias(
        'Bintils.Docker.Containers.Ls'
    )]
    param(
        # docker container --all
        [Parameter()]
            [Alias('All')]
            [switch]$IncludeNotRunning,

        # is: docker --size
        [switch]$ShowSize,

        # is: docker --filter $Filter
        [string]$Filter,

        # Show n last created containers (includes all states) (default -1)
        # native command default is -1
        [Parameter()]
            [Alias('Limit', 'Count', 'Max', 'CreatedCount')]
            [int]$LastCreatedCount = -1,

        # Show the latest created container (includes all states). it returns only one.
        [Parameter()]
            [Alias('LastOne')]
            [switch]$LatestOnly

        # [switch]$ReplaceNoneString,

        # # return only the distinct values
        # [switch]$ListRepoNames,

        # # return only the distinct values
        # [switch]$ListTagNames,

        # [switch]$SummarizeCounts,

        # [ValidateSet(
        #     'Repository',
        #     'Tag',
        #     'Created',
        #     'Size',
        #     'ImageId'
        # )]
        # [string]$SortBy
    )
    [List[Object]]$BinArgs = @(
        'container'
        'ls'
        if( $IncludeNotRunning) { '--all' }
        if( $ShowSize ) { '--size' }
        if( $Filter ) { '--filter' }
        if( $LatestOnly ) { '--latest' }
        if( $LastCreatedCount ) { '--last'; $LastCreatedCount }


        # '--digests'
        '--no-trunc'
    )
    $Options = @{
        ReplaceNoneString = $ReplaceNoneString # $true
    }

    if($SortyBy -in @('Created', 'Size')) {
        Write-warning 'NYI: todo: parse Created and Size to numerical types'
    }

    $BinArgs | Join-String -sep ' ' -op 'Docker Containers => '
        | Bintils.Common.Write-DimText
        | Write-Information -infa 'continue'


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

$nativeDockerScriptBlock = {
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
Register-ArgumentCompleter -CommandName 'docker' -Native -ScriptBlock $nativeDockerScriptBlock -Verbose


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
