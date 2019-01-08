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

I_PATH=$PWD
DOCKER_STACK_NAME=""
EXT_NTWRK=""

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
    docker network rm ${EXT_NTWRK} 2>&1
    if [ "$?" == "${EXT_NTWRK}" ]; then
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
        echo -e "${GREEN} ---------- Creating Docker Swarm  ----------"
        docker swarm init 2>&1
        if [ $? -ne 0 ]; then
            echo $?
            exit 1
        fi
        echo " ---------- Creating Token to join  other ORGs as Manager ---------- ${NC}"
        docker swarm join-token manager | awk 'NR==3 {print}' > tokenToJoinNetwork.txt
        echo -e "${LBLUE}TOKEN TO join swarm as manager ${BROWN}"
        cat tokenToJoinNetwork.txt
        echo -e "${NC}${GREEN}"
    fi
    sleep 1
    DOC_NET=$(docker network ls|grep ${EXT_NTWRK}|awk '{print $2}')
    if [ "${DOC_NET}" != "${EXT_NTWRK}" ]; then
      echo -e " ---------- Creating External Network ----------${NC}"
      docker network create --attachable ${EXT_NTWRK} --driver overlay  2>&1
      if [ $? -ne 0 ]; then
          echo $?
       #exit 1
      fi
    fi
    sleep 1
}

function deployServices() {
  echo -e "${GREEN}Deploying  below services into the network${NC}${BROWN}"
  docker stack deploy ${DOCKER_STACK_NAME} -c docker-compose.yaml 2>&1
  echo -e "${NC}"
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR !!!! Unable to start network${NC}"
    CLI_CONTAINER=$(docker ps |grep tools|awk '{print $1}')
    echo -e "${RED} ERROR LOGS from CLI:"
    docker logs -f ${CLI_CONTAINER}
    echo -e "${NC}"
    exit 1
  fi
  sleep 90
  CLI_CONTAINER=$(docker ps |grep tools|awk '{print $1}')
}
if [ "$1" == "swarmCreate" ]; then 
EXT_NTWRK=$2
swarmCreate
elif [ "$1" == "removeSwarm" ]; then
  echo -e "${GREEN} Removing the network${NC}${BROWN}"
  ProceedFurther
  echo -e "${NC}"
  EXT_NTWRK=$2
  DOCKER_STACK_NAME=$3
  removeSwarm
  clearContainers
  removeUnwantedImages
elif [ "$1" == "deployServices" ]; then
  DOCKER_STACK_NAME=$2
  deployServices
  sleep 30
fi
