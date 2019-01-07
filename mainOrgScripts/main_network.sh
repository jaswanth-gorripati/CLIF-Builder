#!/bin/bash

BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'

set -o allexport
source ./env
set +o allexport

I_PATH=$CPWD

function ProceedFurther () {
  read -p "Continue (y/n)? " ans
  case "$ans" in
    y|Y )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      ProceedFurther
    ;;
  esac
}

function clearContainers () {
  CONTAINER_IDS=$(docker ps -a | grep "dev\|hyperledger/fabric-\|test-vp\|peer[0-9]-" | awk '{print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
  docker volume rm $(docker volume ls|awk '{print $2}')
  if [ $? -ne 0 ]; then
      echo $?
      #exit 1
  fi
}

# Remove the Docker swarm configuration
function swarmRemove() {
    docker stack rm ${DOCKER_STACK_NAME} 2>&1
    if [ $? -ne 0 ]; then
        echo $?
        #exit 1
    fi
    docker network rm ${EXTERNAL_NETWORK} 2>&1
    if [ "$?" == "${EXTERNAL_NETWORK}" ]; then
        echo $?
        #exit 1
    fi
    SWARM_MODE_DEL=$(docker info | grep Swarm | awk '{print $2}')
    if [ "${SWARM_MODE_DEL}" == "active" ]; then
      docker swarm leave --force
      if [ $? -ne 0 ]; then
          echo $?
          #exit 1
      fi
    fi
}
# Create the Docker swarm to deploy stack file 
function swarmCreate() {
    SWARM_MODE=$(docker info | grep Swarm | awk '{print $2}')
    echo "SWARM_MODE = ${SWARM_MODE}"
    if [ "${SWARM_MODE}" != "active" ]; then
        echo " ---------- Creating Docker Swarm  ----------"
        docker swarm init 2>&1
        if [ $? -ne 0 ]; then
            echo $?
            exit 1
        fi
        echo " ---------- Creating Token to join  other ORGs as Manager ----------"
        docker swarm join-token manager | awk 'NR==3 {print}' > token.txt
        echo "TOKEN TO join swarm as manager "
        cat token.txt
        echo
    fi
    sleep 1
    DOC_NET=$(docker network ls|grep ${EXTERNAL_NETWORK}|awk '{print $2}')
    if [ "${DOC_NET}" != "${EXTERNAL_NETWORK}" ]; then
      echo " ---------- Creating External Network ----------"
      docker network create --attachable ${EXTERNAL_NETWORK} --driver overlay  2>&1
      if [ $? -ne 0 ]; then
          echo $?
       #exit 1
      fi
    fi
    sleep 1
}
