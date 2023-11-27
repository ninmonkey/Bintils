
function Bintils.Wsl.Help  {
    Get-Command -m Bintils.completers.wsl
    'https://learn.microsoft.com/en-us/windows/wsl/setup/environment'
}

function __module.OnInit {
    'loading completer wsl....' | write-host -fg '#c186c1' -bg '#6f7057'

    $PSCommandPath | Join-String -op 'Bitils::init wsl completer: {0}' | write-verbose
}

__module.OnInit
# Export-ModuleMember -Function @(
#     'Bintils.*'
# ) -Alias @(
#     'Bintils.*'
# ) -Variable @(
#     'Bintils*'
# )
