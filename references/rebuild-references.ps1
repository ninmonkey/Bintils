function __build.Reference.GitHubCli {
    <#
    .notes
        this gh command is performant enough that I'm not caching it at the moment
        importing bintils calls this
    #>
    param(
        [string]$Destination = 'H:\data\2023\pwsh\PsModules\bintils\references\gh\gh.ps1'
    )

    $MyInvocation.MyCommand.Name | Join-String -f 'enter => {0}' | write-host -back 'darkyellow'

    [ordered]@{
        GhCliVersion =
            gh --version |Join-String -sep ', '
        ExportDate =
            Get-Date | % toString u
        ExportCommand = 'gh completion -s powershell'

    }
        | ConvertTo-Json -depth 3
        | Join-String -op "<#`n.notes`n" -os "`n#>`n"
        | Set-Content -path $Destination -PassThru

    gh completion -s powershell
        | Add-Content -path $Destination -PassThru

    'wrote: "{0}"' -f @( $Destination ) | write-verbose -verb
}

function __build.All {
    # 'enter => __build.All' | write-host -fg 'blue'
    $MyInvocation.MyCommand.Name | Join-String -f 'enter => {0}' | write-host -back 'darkyellow'

    __build.Reference.GitHubCli
}

__build.All

'tip:
    set $env:BASH_COMP_DEBUG_FILE to a filepath to view "gh" completer debug message' | write-host -fore magenta
'tip: to update
    > winget update --id GitHub.cli
' | write-host -fore orange
