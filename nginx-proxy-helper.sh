#!/usr/bin/env bash

GREEN=$(echo -en '\033[00;32m')
YELLOW=$(echo -en '\033[00;33m')
RESTORE=$(echo -en '\033[0m')

test -f .env && source .env

NGINX_PROXY_NETWORK=${NGINX_PROXY_NETWORK:-'nginx-proxy-network'}
NGINX_PROXY_CONTAINER_NAME=${NGINX_PROXY_CONTAINER_NAME:-'nginx-proxy'}
NGINX_PROXY_EXPOSED_PORT=${NGINX_PROXY_EXPOSED_PORT:-'80'}
NGINX_PROXY_IMAGE_NAME=${NGINX_PROXY_IMAGE_NAME:-'jwilder/nginx-proxy'}
NGINX_CONTAINER_NAME_PATTERN=${NGINX_CONTAINER_NAME_PATTERN:-'nginx'}

# return true/false or error if not exist
IS_NGINX_PROXY_RUNNING=$(docker inspect -f "{{.State.Running}}" ${NGINX_PROXY_CONTAINER_NAME} 2> /dev/null)
if [ "$IS_NGINX_PROXY_RUNNING" == "" ]; then
    echo "Running nginx proxy container ${GREEN}${NGINX_PROXY_CONTAINER_NAME}${RESTORE} on port ${GREEN}${NGINX_PROXY_EXPOSED_PORT}${RESTORE}"
    docker run -d -p ${NGINX_PROXY_EXPOSED_PORT}:80 --restart=always --name ${NGINX_PROXY_CONTAINER_NAME} -v /var/run/docker.sock:/tmp/docker.sock:ro ${NGINX_PROXY_IMAGE_NAME}
elif [ "$IS_NGINX_PROXY_RUNNING" == "false" ]; then
    echo "Starting nginx proxy container with name: ${GREEN}${NGINX_PROXY_CONTAINER_NAME}${RESTORE}"
    docker start ${NGINX_PROXY_CONTAINER_NAME} 1> /dev/null
fi

# create network if not exists
docker network inspect ${NGINX_PROXY_NETWORK} &> /dev/null
if [ $? -eq 1 ]
then
    echo "Creating nginx proxy network: ${GREEN}${NGINX_PROXY_NETWORK}${RESTORE}"
    docker network create ${NGINX_PROXY_NETWORK}
fi

# connect jwilder/nginx-proxy container to network if not connected
docker inspect ${NGINX_PROXY_CONTAINER_NAME} --format '{{.NetworkSettings.Networks}}' | grep "${NGINX_PROXY_NETWORK}" &> /dev/null
if [ $? -eq 1 ]
then
    echo "Connecting ${YELLOW}${NGINX_PROXY_CONTAINER_NAME}${RESTORE} to ${NGINX_PROXY_NETWORK}";
    docker network connect ${NGINX_PROXY_NETWORK} ${NGINX_PROXY_CONTAINER_NAME};
fi

# connect running nginx containers to network if not connected
docker ps --filter "status=running" --filter "name=${NGINX_CONTAINER_NAME_PATTERN}" --format '{{.ID}} {{.Networks}} {{.Image}}' \
| grep -v "${NGINX_PROXY_IMAGE_NAME}" \
| cut -d ' ' -f 1,2 \
| grep -v "${NGINX_PROXY_NETWORK}" \
| cut -d ' ' -f 1 \
| while read container_id; do
    # sed to fix forward slash in name
    NAME=$(docker inspect --format="{{.Name}}" ${container_id} | sed "s#^/##");
    echo "Connecting ${YELLOW}${NAME}${RESTORE} to ${NGINX_PROXY_NETWORK}";
    docker network connect ${NGINX_PROXY_NETWORK} ${container_id};
    echo "Restarting ${YELLOW}${NAME}${RESTORE}";
    docker restart ${container_id} 1> /dev/null;
  done
