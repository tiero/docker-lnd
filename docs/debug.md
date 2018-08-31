# Debugging

## Viewing lnd Logs

    docker logs lnd-node

## Running Bash in Docker Container

_Note:_ This container will be run in the same way as the lnd node, but will not connect to already running containers or processes.

    docker run -v lnd-data:/lnd --rm -it lnzap/lnd bash -l

You can also attach bash into running container to debug running lnd

    docker exec -it lnd-node bash -l
