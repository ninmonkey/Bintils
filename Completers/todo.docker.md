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

## misc commands dump

```ps1
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