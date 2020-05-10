#!/bin/bash
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
CPWD=~/CLIF

function gCleanFolder() {
    rm -rf $CPWD/*
}
function gFolder() {
    mkdir -p $CPWD/${ORG_NAME}/
    cp -rf bin/ $CPWD/${ORG_NAME}/
    cp -rf chaincode/ $CPWD/${ORG_NAME}/
    #cp  ./mainOrgScripts/fabric-ca-server-config.yaml $CPWD/${ORG_NAME}/

}

function gCryptoOrderer() {
    cat << EOF > $CPWD/${ORG_NAME}/crypto-config.yaml
OrdererOrgs:
  - Name: Orderer
    Domain: example.com
    Specs:
EOF
if [ "${ORDR_TYPE}" != "SOLO" ]; then
    for ordr in `seq 0 $(expr $NO_OF_PEERS_ORDRS - 1)`
    do
    cat << EOF >> $CPWD/${ORG_NAME}/crypto-config.yaml
      - Hostname: orderer${ordr}
EOF
done
else
    cat << EOF >> $CPWD/${ORG_NAME}/crypto-config.yaml
      - Hostname: orderer0
EOF
fi
}
function gCryptoPeers() {
    ORG_NAME=$1
    NO_OF_PEERS=$2
    ORDERER_EXISTS=$3
    if [ "${ORDERER_EXISTS}" == "true" ]; then
        ORDR_TYPE=$4
        if [ "${ORDR_TYPE}" != "SOLO" ]; then
            NO_OF_PEERS_ORDRS=$5
        fi
    fi
    gFolder
    if [ ${ORDERER_EXISTS} == true ]; then 
        gCryptoOrderer
    fi
    cat << EOF >> $CPWD/${ORG_NAME}/crypto-config.yaml
PeerOrgs:
  - Name: ${ORG_NAME}
    Domain: ${ORG_NAME}.example.com
    EnableNodeOUs: true
    SANS:
      - 0.0.0.0
    Template:
      Count: ${NO_OF_PEERS}
    Users:
      Count: 1
EOF

echo -e "${GREEN} crypto-config.yaml for ${ORG_NAME} is generated${NC}"
}