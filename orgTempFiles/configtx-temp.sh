#!/bin/bash
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
CPWD=~/CLIF

function setOrg() {
    ORG_NAME=$1
}
function ctxFile() {
    cat << EOF > $CPWD/${ORG_NAME}/configtx.yaml
#

---
EOF
}

function addOrgTxt() {
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
################################################################################
#
#   Section: Organizations
#
################################################################################
Organizations:
EOF
}
function ctxOrgaizations() {
    addOrgTxt
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    - &OrdererOrg
        Name: OrdererOrg
        ID: OrdererMSP
        MSPDir: crypto-config/ordererOrganizations/example.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('OrdererMSP.admin')"

    - &${ORG_NAME}
        Name: ${ORG_NAME}MSP
        ID: ${ORG_NAME}MSP
        MSPDir: crypto-config/peerOrganizations/${ORG_NAME}.example.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('${ORG_NAME}MSP.admin', '${ORG_NAME}MSP.peer', '${ORG_NAME}MSP.client')"
            Writers:
                Type: Signature
                Rule: "OR('${ORG_NAME}MSP.admin', '${ORG_NAME}MSP.client')"
            Admins:
                Type: Signature
                Rule: "OR('${ORG_NAME}MSP.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('${ORG_NAME}MSP.peer')"
        AnchorPeers:
            - Host: peer0.${ORG_NAME}.example.com
              Port: 7051
EOF
}

function ctxaddAllOrgs() {
ORG_NAME1=$1
addOrgTxt
cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    - &${ORG_NAME1}
        Name: ${ORG_NAME1}MSP
        ID: ${ORG_NAME1}MSP
        MSPDir:  HOME_PATH/CLIF/${ORG_NAME1}/crypto-config/peerOrganizations/${ORG_NAME1}.example.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('${ORG_NAME1}MSP.admin', '${ORG_NAME1}MSP.peer', '${ORG_NAME1}MSP.client')"
            Writers:
                Type: Signature
                Rule: "OR('${ORG_NAME1}MSP.admin', '${ORG_NAME1}MSP.client')"
            Admins:
                Type: Signature
                Rule: "OR('${ORG_NAME1}MSP.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('${ORG_NAME1}MSP.peer')"
        AnchorPeers:
            - Host: peer0.${ORG_NAME1}.example.com
              Port: 7051
EOF
}

function ctxOrderer() {
    CTXORDRTYP=$1
    CTX_NO_ORDR=$(expr $2 - 1)
    CTX_NO_KFS=$(expr $3 - 1)
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
################################################################################
#
#   SECTION: Orderer
#
################################################################################
Orderer: &OrdererDefaults
EOF
if [ "$CTXORDRTYP" == "etcdraft" ]; then
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    OrdererType: $CTXORDRTYP
    Addresses:
EOF
else
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    OrdererType: ${CTXORDRTYP}
    Addresses:
EOF
fi
for ordr in `seq 0 ${CTX_NO_ORDR}`
do
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
        - orderer${ordr}.example.com:7050
EOF
done
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    BatchTimeout: 1s
    BatchSize:
        MaxMessageCount: 50
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 1 MB
    Kafka:
        Brokers:
EOF
for kf in `seq 0 ${CTX_NO_KFS}`
do
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
            - kafka${kf}:9092
EOF
done
cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"
Application: &ApplicationDefaults
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        LifecycleEndorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"
        Endorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"

Channel: &ChannelDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    Capabilities:
        <<: *ChannelCapabilities
EOF
}

function ctxGenesisProfile() {
ORG_NAME=$1
CTXORDRTYP=$2
CTX_NO_ORDR=$(expr $3 - 1)
GENESIS_NAME=$4
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
################################################################################
#
#   Profile
#
################################################################################
Profiles:
    ${GENESIS_NAME}:
        <<: *ChannelDefaults
        Orderer:
            <<: *OrdererDefaults
            OrdererType: ${CTXORDRTYP}
EOF
if [ "$CTXORDRTYP" == "etcdraft" ]; then
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
            EtcdRaft:
                Consenters:
EOF
    for order in `seq 0 ${CTX_NO_ORDR}`
    do
        cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
                - Host: orderer${order}.example.com
                  Port: 7050
                  ClientTLSCert: crypto-config/ordererOrganizations/example.com/orderers/orderer${order}.example.com/tls/server.crt
                  ServerTLSCert: crypto-config/ordererOrganizations/example.com/orderers/orderer${order}.example.com/tls/server.crt
EOF
    done
fi
cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
            Addresses:
EOF
for order in `seq 0 ${CTX_NO_ORDR}`
do
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
                - orderer${order}.example.com:7050
EOF
done
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
            Organizations:
                - *OrdererOrg
            Capabilities:
                <<: *OrdererCapabilities
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *${ORG_NAME}
            Capabilities:
                <<: *ApplicationCapabilities
        Consortiums:
            SampleConsortium:
                Organizations:
                    - *${ORG_NAME}
EOF
}

function ctxAddConsor() {
cons=("$@")
cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
            ${cons[0]}:
                Organizations:
EOF
for con in `seq 2 $(expr ${cons[1]} + 1)`
do
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
                    - *${cons[con]}
EOF
done
}

function ctxChannelProfile() {
    chDetails=$1
    ORG_NAME=$2
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    ${chDetails}:
        Capabilities:
            <<: *ChannelCapabilities
        <<: *ChannelDefaults
        Consortium: SampleConsortium
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *${ORG_NAME}
            Capabilities:
                <<: *ApplicationCapabilities
EOF
}

function ctxAllChannels() {
    chDetails=("$@")
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
    ${chDetails[0]}:
        Capabilities:
            <<: *ChannelCapabilities
        Consortium: ${chDetails[1]}
        Application:
            <<: *ApplicationDefaults
            Organizations:
EOF
for chorg in `seq 3 $(expr ${chDetails[2]} + 2)`
do
cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
                - *${chDetails[${chorg}]}
EOF
done
cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
            Capabilities:
                <<: *ApplicationCapabilities
EOF
}

function ctxCapabilities() {
    cat << EOF >> $CPWD/${ORG_NAME}/configtx.yaml
################################################################################
#
#   SECTION: Application
#
################################################################################

Capabilities:
    Channel: &ChannelCapabilities
        V2_0: true
    Orderer: &OrdererCapabilities
        V2_0: true
    Application: &ApplicationCapabilities
        V2_0: true
EOF

echo -e "${GREEN} Configtx.yaml File for ${ORG_NAME} is generated"
}