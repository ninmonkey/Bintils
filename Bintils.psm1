

$importModuleSplat = @{
    PassThru = $true
    Force = $true
}

Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.wsl.psm1')
