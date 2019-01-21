#!/bin/bash

BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
MPT=~/HAND

# set -o allexport
# source ./env
# set +o allexport

I_PATH=$PWD
C_ORG=""
DOCKER_STACK_NAME=""
EXT_NTWRK=""
CH_NAME=""

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
        echo " ---------- Creating Docker Swarm  ----------"
        docker swarm init 2>&1
        if [ $? -ne 0 ]; then
            echo $?
            exit 1
        fi
        echo " ---------- Creating Token to join  other ORGs as Manager ----------"
        docker swarm join-token manager | awk 'NR==3 {print}' > tokenToJoinNetwork.sh
        echo "TOKEN TO join swarm as manager "
        cat tokenToJoinNetwork.sh
        chmod +x tokenToJoinNetwork.sh
        echo
      else
        echo -e "${RED} This node is already in Swarm mode !!${NC}" 
        exit 1
    fi
    sleep 1
    DOC_NET=$(docker network ls|grep ${EXT_NTWRK}|awk '{print $2}')
    if [ "${DOC_NET}" != "${EXT_NTWRK}" ]; then
      echo " ---------- Creating External Network ----------"
      docker network create --attachable ${EXT_NTWRK} --driver overlay  2>&1
      if [ $? -ne 0 ]; then
          echo $?
       #exit 1
      fi
    fi
    sleep 1
}

function swarmJoin() {
    SWARM_MODE=$(docker info | grep Swarm | awk '{print $2}')
    echo "SWARM_MODE = ${SWARM_MODE}"
    if [ "${SWARM_MODE}" != "active" ]; then
      if [ -f ".token.sh" ]; then
        #chmod +x token.sh
        ./tokenToJoinNetwork.sh
      else
        echo "Docker Swarm join token not found ... Exiting :("
        exit 1
      fi
    fi
    sleep 1
    DOC_NET=$(docker network ls|grep ${EXTERNAL_NETWORK}|awk '{print $2}')
    if [ "${DOC_NET}" != "${EXTERNAL_NETWORK}" ]; then
          echo "External network not found ... Exiting :("
          exit 1
    fi
    sleep 1
}

function buildNetwork() {
  echo -e "${GREEN}Deploying  below services into the network${NC}${BROWN}"
  docker stack deploy ${DOCKER_STACK_NAME} -c docker-compose.yaml 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR !!!! Unable to start network${NC}"
    CLI_CONTAINER=$(docker ps |grep ${C_ORG}_cli|awk '{print $1}')
    echo -e "${RED} ERROR LOGS from CLI:"
    docker logs -f ${CLI_CONTAINER}
    echo -e "${NC}"
    exit 1
  fi
  echo -e "${NC}"
  sleep 90
  CLI_CONTAINER=$(docker ps |grep ${C_ORG}_cli|awk '{print $1}')
  docker exec $CLI_CONTAINER ./joinNetwork.sh $C_ORG $CH_NAME $CC_NAME $CC_VER $OR_AD $CC_PTH $P_CNT
}

if [ "$1" == "swarmCreate" ]; then 
  EXT_NTWRK=$2
  swarmCreate
elif [ "$1" == "removeSwarm" ]; then
  EXT_NTWRK=$2
  DOCKER_STACK_NAME=$3
  removeSwarm
  clearContainers
  removeUnwantedImages
elif [ "$1" == "buildNetwork" ]; then
  #joinSwarm $2
  DOCKER_STACK_NAME=$2
  C_ORG=$3
  CH_NAME=$4
  CC_NAME=$5
  CC_VER=$6
  OR_AD=$7
  CC_PTH=$8
  P_CNT=$(expr $9 - 1)
  buildNetwork
fi
