#!/bin/bash

DTSPATH="./services.yaml"
function addCli() {
    PORG_NAME=$1
    EXTERNAL_NETWORK=$2
    d_type="$3"
if [ "$d_type" != "Docker-compose" ]; then
cat << EOF >> ${DTSPATH}
  ${PORG_NAME}_cli:
    image: hyperledger/fabric-tools:1.4.0
    deploy:
      replicas: 1
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    hostname: ${PORG_NAME}_cli
EOF
else
cat << EOF >> ${DTSPATH}
  ${PORG_NAME}_cli:
    image: hyperledger/fabric-tools:1.4.0
    container_name: ${PORG_NAME}_cli
EOF
fi
cat << EOF >> ${DTSPATH}
    tty: true
    stdin_open: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      #- FABRIC_LOGGING_SPEC=DEBUG
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_ID=${PORG_NAME}_cli
      - CORE_PEER_ADDRESS=peer0.${PORG_NAME}.example.com:7051
      - CORE_PEER_LOCALMSPID=${PORG_NAME}MSP
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${PORG_NAME}.example.com/peers/peer0.${PORG_NAME}.example.com/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${PORG_NAME}.example.com/peers/peer0.${PORG_NAME}.example.com/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${PORG_NAME}.example.com/peers/peer0.${PORG_NAME}.example.com/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${PORG_NAME}.example.com/users/Admin@${PORG_NAME}.example.com/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash
    volumes:
      - /var/run/:/host/var/run/
      - ./chaincode/:/opt/gopath/src/github.com/chaincode
      - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
      - ./:/opt/gopath/src/github.com/hyperledger/fabric/peer/
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - ${PORG_NAME}.cli 
EOF
}
#addCli org1 ext
