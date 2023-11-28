$CmdList = @(
    'attach'
'build'
'commit'
'cp'
'create'
'diff'
'events'
'exec'
'export'
'history'
'images'
'import'
'info'
'inspect'
'kill'
'load'
'login'
'logout'
'logs'
'pause'
'port'
'ps'
'pull'
'push'
'rename'
'restart'
'rm'
'rmi'
'run'
'save'
'search'
'start'
'stats'
'stop'
'tag'
'top'
'unpause'
'update'
'version'
'wait'
)

$cmdsList_manage = @(
    'builder'
    'buildx*'
    'compose*'
    'config'
    'container'
    'context'
    'dev*'
    'extension'
    'image'
    'manifest'
    'network'
    'node'
    'plugin'
    'sbom*'
    'scan*'
    'scout*'
    'secret'
    'service'
    'stack'
    'swarm'
    'system'
    'trust'
    'volume'
) -replace [regex]::escape('*'), ''

throw 'slow, run these manually'

$cmdList | %{
    $name = $_

    docker $name --help
        | Set-Content (Join-path 'H:\data\2023\pwsh\PsModules\Bintils\Import\docker' "${name}.txt") -PassThru
}
$cmdsList_manage | %{
    $name = $_
    docker $name --help
        | Set-Content (Join-path 'H:\data\2023\pwsh\PsModules\Bintils\Import\docker\' "manage.${name}.txt") -PassThru
}
