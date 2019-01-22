#!/bin/bash
DTSPATH="./services.yaml"
function addPeer() {
    PORG_NAME=$1
    P_ID=$2
    AddNumber=$3
    port1=$(expr 7051 + $3)
    port2=$(expr 7053 + $3)
    EXTERNAL_NETWORK=$4
    couchdb=$5
    d_type="$6"
if [ "$d_type" != "Docker-compose" ]; then
cat << EOF >> ${DTSPATH}
  peer${P_ID}_${PORG_NAME}:
    image: hyperledger/fabric-peer:x86_64-1.1.0
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    hostname: peer${P_ID}.${PORG_NAME}.example.com
EOF
else
cat << EOF >> ${DTSPATH}
  peer${P_ID}.${PORG_NAME}.example.com:
    image: hyperledger/fabric-peer:x86_64-1.1.0
    container_name: peer${P_ID}.${PORG_NAME}.example.com
EOF
fi
cat << EOF >> ${DTSPATH}
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      # the following setting starts chaincode containers on the same
      # bridge network as the peers
      # https://docs.docker.com/compose/networking/
EOF
if [ "$d_type" != "Docker-compose" ]; then
cat << EOF >> ${DTSPATH}
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${EXTERNAL_NETWORK}
EOF
else
cat << EOF >> ${DTSPATH}
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=hanb_${EXTERNAL_NETWORK}
EOF
fi
cat << EOF >> ${DTSPATH}
      #- CORE_LOGGING_LEVEL=INFO
      - CORE_LOGGING_LEVEL=DEBUG
      - CORE_CHAINCODE_STARTUPTIMEOUT=1200s
      - CORE_CHAINCODE_LOGGING_LEVEL=DEBUG
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_GOSSIP_USELEADERELECTION=true
      - CORE_PEER_GOSSIP_ORGLEADER=false
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
      - CORE_PEER_ID=peer${P_ID}.${PORG_NAME}.example.com
      - CORE_PEER_ADDRESS=peer${P_ID}.${PORG_NAME}.example.com:7051
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer${P_ID}.${PORG_NAME}.example.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer${P_ID}.${PORG_NAME}.example.com:7051
      - CORE_PEER_LOCALMSPID=${PORG_NAME}MSP
EOF
if [ ${couchdb} == true ]; then 
cat << EOF >> ${DTSPATH}
      - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
      - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb${P_ID}.${PORG_NAME}:5984
EOF
fi
cat << EOF >> ${DTSPATH}
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config/peerOrganizations/${PORG_NAME}.example.com/peers/peer${P_ID}.${PORG_NAME}.example.com/msp:/etc/hyperledger/fabric/msp
      - ./crypto-config/peerOrganizations/${PORG_NAME}.example.com/peers/peer${P_ID}.${PORG_NAME}.example.com/tls:/etc/hyperledger/fabric/tls
      - peer${P_ID}.${PORG_NAME}.example.com:/var/hyperledger/production
      #- ./ledger/peer${P_ID}.${PORG_NAME}.exapmle.com:/var/hyperledger/production
    ports:
      - "${port1}:7051"
      - "${port2}:7053"
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
EOF

if [ ${couchdb} == true ]; then 
cat << EOF >> ${DTSPATH}
    depends_on:
      - couchdb${P_ID}.${PORG_NAME}
EOF
fi
cat << EOF >> ${DTSPATH}
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - peer${P_ID}.${PORG_NAME}.example.com

EOF
}
#addPeer org1 2 2000 ext true