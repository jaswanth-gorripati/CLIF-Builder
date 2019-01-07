#!/bin/bash
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
PWD=~/HANB

function gCleanFolder() {
    rm -rf $PWD/*
}
function gFolder() {
    mkdir -p $PWD/${ORG_NAME}/
    cp -rf bin/ $PWD/${ORG_NAME}/

}

function gCryptoOrderer() {
    cat << EOF > $PWD/${ORG_NAME}/crypto-config.yaml
# ---------------------------------------------------------------------------
# "OrdererOrgs" - Definition of organizations managing orderer nodes
# ---------------------------------------------------------------------------
OrdererOrgs:
  # ---------------------------------------------------------------------------
  # Orderer
  # ---------------------------------------------------------------------------
  - Name: Orderer
    Domain: example.com
    # ---------------------------------------------------------------------------
    # "Specs" - See PeerOrgs below for complete description
    # ---------------------------------------------------------------------------
    Specs:
EOF
if [ ${ORDR_TYPE} == "KAFKA" ]; then
    for ordr in `seq 0 $(expr $NO_OF_PEERS_ORDRS - 1)`
    do
    cat << EOF >> $PWD/${ORG_NAME}/crypto-config.yaml
      - Hostname: orderer${ordr}
EOF
done
else
    cat << EOF >> $PWD/${ORG_NAME}/crypto-config.yaml
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
        if [ "${ORDR_TYPE}" == "KAFKA" ]; then
            NO_OF_PEERS_ORDRS=$5
        fi
    fi
    gFolder
    if [ ${ORDERER_EXISTS} == true ]; then 
        gCryptoOrderer
    fi
    cat << EOF >> $PWD/${ORG_NAME}/crypto-config.yaml
# ---------------------------------------------------------------------------
# "PeerOrgs" - Definition of organizations managing peer nodes
# ---------------------------------------------------------------------------
PeerOrgs:
  # ---------------------------------------------------------------------------
  # ${ORG_NAME}
  # ---------------------------------------------------------------------------
  - Name: ${ORG_NAME}
    Domain: ${ORG_NAME}.example.com
    EnableNodeOUs: true
    Template:
      Count: ${NO_OF_PEERS}
    Users:
      Count: 1
EOF

echo -e "${GREEN} crypto-config.yaml for ${ORG_NAME} is generated${NC}"
}