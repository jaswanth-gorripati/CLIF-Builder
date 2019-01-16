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
    CC_S_P=github.com/chaincode/chaincode_example02/go/
    CC_VER=$6
    ORD_adr=$7
    P_CT=$8
    #startSwarmNetwork
    startService
    deployNetwork
}
function sendOrderer() {
    cp -rf ~/HANB/$1/crypto-config/ordererOrganizations ~/HANB/$2/crypto-config/
}
function addNewOrg() {
    M_ORG=$1
    ad_Org=$2
    CH_NME=$3
    O_TPE=$4
    AP_cnt=$5
    if [ ! -f "${ad_Org}.json" ]; then
        cp ~/HANB/${ad_Org}/${ad_Org}.json ~/HANB/${M_ORG}/
    fi
    CLI_CONTAINER=$(docker ps |grep ${M_ORG}_cli|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./addNewOrg.sh $ad_Org $CH_NME $O_TPE $AP_cnt $M_ORG
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
    sendOrderer $M_ORG $ad_Org
}

function AddOrgToNetwork() {
    ad_Org=$1
    CH_NME=$2
    O_TPE=$3
    DS_NAME=$4
    CC_NAME=$5
    CC_VER=$6
    if [ "${O_TPE}" == "KAFKA" ]; then
        OR_AD="orderer0"
    else
        OR_AD="orderer0"
    fi
    AP_CN=$7
    c_path=$PWD
    cd ~/HANB/${ad_Org}/
    ./dockerSetup.sh "buildNetwork" ${DS_NAME} ${ad_Org} ${CH_NME} ${CC_NAME} ${CC_VER} ${OR_AD} "github.com/chaincode/chaincode_example02/go/" $AP_CN
    cd $c_path
}
function updateChannelConfig() {
    m_org=$1
    ad_org=$2
    CH_NME=$3
    tr="$"
    cat << EOF > ~/HANB/${m_org}/updateChannelConfig.sh
#!/bin/bash
CHANNEL_NAME=${tr}2
DOMAIN=${tr}1
ORDERER_URL=orderer0.example.com
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer channel update -f ${tr}{DOMAIN}_update_in_envelope.pb -c ${tr}CHANNEL_NAME -o ${tr}ORDERER_URL:7050 --tls --cafile ${tr}ORDERER_CA 2>&1
if [ ${tr}? -ne 0 ];then
  echo "******************** FAILED TO ADD ${tr}DOMAIN INTO THE NETWORK *********************"
else
  echo "******************** ${tr}{DOMAIN} ORGANISATION ADDED TO NETWORK **********************"
fi
exit 0
EOF
    chmod +x ~/HANB/${m_org}/updateChannelConfig.sh
    CLI_CONTAINER=$(docker ps |grep ${m_org}_cli|awk '{print $1}')
    if [ "${CLI_CONTAINER}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
    fi
    docker exec ${CLI_CONTAINER} ./updateChannelConfig.sh $ad_Org $CH_NME
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}

function signChannelConfig() {
    m_org=$1
    ad_org=$2
    CH_NME=$3
    sin_org=$5
    p_cnt=$6
    tr="$"
    cat << EOF > ~/HANB/${ad_org}/signChannelConfig.sh
#!/bin/bash
P_CN=${tr}1
M_DMIN=${tr}2
DOMAIN=${tr}3
peer=0
while [ "${tr}peer" != "${tr}P_CN" ]
do
    export CORE_PEER_ADDRESS=peer${tr}peer.${tr}{M_DMIN}.example.com:7051
    peer channel signconfigtx -f ${tr}{DOMAIN}_update_in_envelope.pb
    peer=${tr}(expr ${tr}peer + 1)
done
export CORE_PEER_ADDRESS=peer0.${tr}{M_DMIN}.example.com:7051
exit 0
EOF
chmod +x ~/HANB/${ad_org}/signChannelConfig.sh
M_C_ID=$(docker ps |grep ${m_org}_cli|awk '{print $1}')
 if [ "${M_C_ID}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
fi
A_C_ID=$(docker ps |grep ${ad_org}_cli|awk '{print $1}')
 if [ "${A_C_ID}" == "" ]; then
    echo -e "${RED}CONTAINER NOT found !!! ${NC}"
    exit 1
fi
d_pth=/opt/gopath/src/github.com/hyperledger/fabric/peer/
docker cp $M_C_ID:$d_pth/${sin_org}_update_in_envelope.pb ./${sin_org}_update_in_envelope.pb
docker cp ./${sin_org}_update_in_envelope.pb $A_C_ID:$d_pth 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
docker exec ${A_C_ID} ./signChannelConfig.sh $p_cnt $ad_org $sin_org
    if [ $? -ne 0 ]; then
        echo "ERROR !!!! failed"
        exit 1
    fi
}