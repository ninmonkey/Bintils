

$importModuleSplat = @{
    PassThru = $true
    Force = $true
}

Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.wsl.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.docker.psm1')

. (gi 'H:\data\2023\pwsh\PsModules\bintils\references\rebuild-references.ps1')
'currently rebuilds on invoke, should cache it. 👷‍♂️ although gh is fast-ish'
    | write-host -fore 'magenta' -bg 'gray15'

. (gi 'H:\data\2023\pwsh\PsModules\Bintils\references\gh\gh.ps1')

# Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.docker.psm1')
