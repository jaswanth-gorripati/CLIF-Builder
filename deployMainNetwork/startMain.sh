#!/bin/bash
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
org_pth=""
EXT_NW=""
D_STK=""
#declare -A orgs
function sendTokenToOrgs() {
    ./dockerSetup.sh "sendJoinToken" ${orgs[@]}
}
function startSwarmNetwork() {
    Cr_D=$PWD
    cd $1
    EXT_NW=$2
    orgs=("${@:3}")
    chmod +x ./dockerSetup.sh 
    chmod +x ./buildingNetwork.sh
    ./dockerSetup.sh "swarmCreate" ${EXT_NW}
    #sendTokenToOrgs
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
    CLI_CONTAINER=$(docker ps |grep ${D_NME}_cli|awk '{print $1}')
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
    CC_S_P=/opt/gopath/src/github.com/chaincode/chaincode_example02/go/
    CC_VER=$6
    ORD_adr=$7
    P_CT=$8
    #startSwarmNetwork
    startService
    deployNetwork
}
function addNewOrg() {
    M_ORG=$1
    ad_Org=$2
    CH_NME=$3
    O_TPE=$4
    if [ ! -f "${ad_Org}.json" ]; then
        cp ~/HANB/${ad_Org}/${ad_Org}.json ~/HANB/${M_ORG}/
    fi
    CLI_CONTAINER=$(docker ps |grep ${M_ORG}_cli|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./addNewOrg.sh $ad_Org $CH_NME $O_TPE
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}

function AddOrgToNetwork() {
    ad_Org=$1
    CH_NME=$2
    O_TPE=$3
    DS_NAME=$4
    CC_NAME=$5
    CC_VER=$6
    if [ "${O_TPE}" == "KAFKA" ]; then
        OR_AD="orderer1"
    else
        OR_AD="orderer0"
    fi
    c_path=$PWD
    cd ~/HANB/${ad_Org}/
    ./dockerSetup.sh "buildNetwork" ${DS_NAME} ${ad_Org} ${CH_NME} ${CC_NAME} ${CC_VER} ${OR_AD} "github.com/chaincode/chaincode_example02/go/"
    cd c_path
}