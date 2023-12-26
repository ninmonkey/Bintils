$script:LoaderConfig = @{
    LoadAggressiveAliasesForDocker = $true # these are loaded into globa scope and they de-load when the module does.
}

$importModuleSplat = @{
    PassThru = $true
    Force = $true
}

Import-Module @importModuleSplat (Join-path $PSScriptRoot './bintils.common.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.wsl.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.docker.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.AwsCli.psm1')
Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.lucidlink.psm1')

# Export-ModuleMember -Function @('Bdoc.*') -Alias @('Bdoc.*')

# Import-Module @importModuleSplat (Join-path $PSScriptRoot './Completers/bintils.completers.docker.psm1')

'wip: Bintils.psm1 currently rebuilds on invoke, I should cache it. 👷‍♂️ although gh invoke is fast'
    | Write-Host -fg 'magenta' -bg 'gray15'

. (gi -ea 'continue' (Join-path $PSScriptRoot 'references/rebuild-references.ps1'))
    # todo: performance test compare whether (Test-path) else System.IO methods are faster than get-item
    # mainly noticable when multiple tabs open at once, sometimes a file lock overlaps

if( $dotSrc = gi -ea 'continue' (Join-path $PSScriptRoot 'references/gh\gh.ps1')) {
    . $DotSrc
}

<#
Globalize some aliases
#>
if( $script:LoaderConfig.LoadAggressiveAliasesForDocker) {
    # New-Alias 'bDoc.Container' 'Bintils.Docker.Parse.Containers.Get' -Description 'Exporting an alias from Bintils.Docker that returns containers as objects' -PassThru | out-string | write-warning
    # edit: moved alias to the sub module itself
    # New-Alias 'bDoc.Container' 'bintils.docker.containers.Ls' -Description 'Exporting an alias from Bintils.Docker that returns containers as objects' -Scope global -PassThru
    # | out-string | write-warning
}
