
- [refs](#refs)
- [Commands](#commands)
- [docker Go format string syntax](#docker-go-format-string-syntax)
- [misc commands dump](#misc-commands-dump)
  - [format string session 🎨](#format-string-session-)


## refs

- CLI
- [about_CLI](https://docs.docker.com/engine/reference/commandline/cli/)
- [run](https://docs.docker.com/engine/reference/run/)
  - [compose run](https://docs.docker.com/engine/reference/commandline/compose_run/)

## Commands

```ps1
# https://docs.docker.com/engine/reference/commandline/image_prune/
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}'
docker image prune -a --force --filter "until=2017-01-04T00:00:00"
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}'
# > 10 days (240 hours)
# filter syntax: https://docs.docker.com/engine/reference/commandline/image_prune/#filter
docker image prune -a --force --filter "until=240h"
```
## docker Go format string syntax

https://docs.docker.com/config/formatting/

```ps1
# nix
docker inspect --format '{{join .Args " , "}}' container
# windows pwsh
docker inspect --format '{{join .Args \" , \"}}' container
```

## misc commands dump

```ps1

## IP of one
docker inspect --format='{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}' $containerName

docker container ls --last -1 --no-trunc (Bintils.Docker.NewTemplateString Json.All) # |Jq


docker network ls --no-trunc
# https://docs.docker.com/network/drivers/bridge/#configure-the-default-bridge-network

# https://docs.docker.com/config/containers/logging/local/
docker run \
      --log-driver local --log-opt max-size=10m \
      alpine echo hello world

# https://docs.docker.com/config/containers/logging/awslogs/
docker run --log-driver=awslogs --log-opt awslogs-region=us-east-1 ...
docker run --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group=myLogGroup ...

docker inspect -f '{{.HostConfig.LogConfig.Type}}' $ContainerName
```

### format string session 🎨
```ps1

Pwsh 7.4.0> 🐒
docker inspect --format='{{println .NetworkSettings}}' $containerName
&{{ 5355b0826bb57f01a761df22ca748861c948dcd7289776aa8a502bf3a6c85d31 false  0 map[] /var/run/docker/netns/5355b0826bb5 [] []} {54b3dfe6208
d5d459e465463cbf89c0db1286d4a7e995054e6af509c07b 172.17.0.1  0 172.17.0.2 16  02:42:ac:11:00:02} map[bridge:0xc000558000]}

Pwsh 7.4.0> 🐒
docker inspect --format='{{println .NetworkSettings}}' $containerName
```