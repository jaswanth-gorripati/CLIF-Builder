#!/bin/bash
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
org_pth=""
EXT_NW=""
D_STK=""
function startSwarmNetwork() {
    Cr_D=$PWD
    cd $org_pth
    chmod +x ./dockerSetup.sh 
    chmod +x ./buildingNetwork.sh
    ./dockerSetup.sh "swarmCreate" ${EXT_NW}
    cd $Cr_D

}
function startService() {
    Cr_D=$PWD
    cd $org_pth
    chmod +x ./dockerSetup.sh 
    ./dockerSetup.sh "deployServices" ${D_STK}
    cd $Cr_D
}
function deployNetwork() {
    CLI_CONTAINER=$(docker ps |grep tools|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./buildingNetwork.sh $CH_NME $D_NME $CC_S_P $CC_VER $ORD_adr $P_CT
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}
function runMainNetwork() {
    org_pth=$1
    EXT_NW=$2
    D_STK=$3
    CH_NME=$4
    D_NME=$5
    CC_S_P=/opt/gopath/src/github.com/chaincode/chaincode_example02/node/
    CC_VER=$6
    ORD_adr=$7
    P_CT=$8
    startSwarmNetwork
    startService
    deployNetwork
}