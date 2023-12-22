

$importModuleSplat = @{
    PassThru = $true
    Force = $true
}

Import-Module @importModuleSplat (Join-path $PSScriptRoot './bintils.common.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.wsl.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.docker.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.AwsCli.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.lucidlink.psm1')

# Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.docker.psm1')

'wip: Bintils.psm1 currently rebuilds on invoke, I should cache it. 👷‍♂️ although gh invoke is fast'
    | Write-Host -fg 'magenta' -bg 'gray15'

. (gi -ea 'continue' (Join-path $PSScriptRoot 'references/rebuild-references.ps1'))
    # todo: performance test compare whether (Test-path) else System.IO methods are faster than get-item
    # mainly noticable when multiple tabs open at once, sometimes a file lock overlaps

if( $dotSrc = gi -ea 'continue' (Join-path $PSScriptRoot 'references/gh\gh.ps1')) {
    . $DotSrc
}
