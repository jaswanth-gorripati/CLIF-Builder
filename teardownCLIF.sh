#!/bin/bash

STACK_NAME=$(docker stack ls| awk 'FNR==2{print $1}')
docker stack rm ${STACK_NAME}
echo y|docker network prune
docker swarm leave --force
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker rmi $(docker images| grep dev|awk '{print $3}')
echo y| docker volume prune
rm -rf ~/CLIF/

docker volume ls
docker network ls
docker ps -a
docker images| grep dev
