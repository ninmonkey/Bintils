function __old__Bintils.Docker.Parse.Containers.Get__iter0 {
    <#
    .SYNOPSIS
        parse docker containers command
    .EXAMPLE
        Pwsh> Bintils.Docker.Parse.Containers
    .EXAMPLE

        docker container ls --last -1 --no-trunc '--format={{json .}}' | Json.from
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
        # 'Bintils.Docker.Containers.Ls'
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
