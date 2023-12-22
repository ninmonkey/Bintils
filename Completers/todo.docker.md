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
