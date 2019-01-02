#!/bin/bash
DTSPATH="./services.yaml"
function addCa() {
    PORG_NAME=$1
    AddNumber=$2
    port1=$(expr 7054 + $2)
    EXTERNAL_NETWORK=$3
cat << EOF > ${DTSPATH}
  ca_${PORG_NAME}:
    image: hyperledger/fabric-ca:x86_64-1.1.0
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-${PORG_NAME}
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.${PORG_NAME}.example.com-cert.pem
      - FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server-config/CA_PRIVATE_KEY
    ports:
      - "${port1}:7054"
    command: sh -c 'fabric-ca-server start --ca.certfile /etc/hyperledger/fabric-ca-server-config/ca.${PORG_NAME}.example.com-cert.pem --ca.keyfile /etc/hyperledger/fabric-ca-server-config/CA_PRIVATE_KEY -b admin:adminpw -d'
    volumes:
      - ./crypto-config/peerOrganizations/${PORG_NAME}.example.com/ca/:/etc/hyperledger/fabric-ca-server-config
      #- ./ledger/ca-${PORG_NAME}:/etc/hyperledger/fabric-ca-server
    hostname: ca-${PORG_NAME}
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - ca-${PORG_NAME}
EOF
}
#addCa "org1" "1" "0" "byfn" "./ca.yaml"