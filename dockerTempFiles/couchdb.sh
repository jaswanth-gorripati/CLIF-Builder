#!/bin/bash

DTSPATH="./services.yaml"
function addCouch() {
    COUCH_ID=$1
    AddNumber=$2
    port1=$(expr 5984 + $2)
    EXTERNAL_NETWORK=$3
    CORG=$4
    cat << EOF >> ${DTSPATH}
  couchdb${COUCH_ID}_${CORG}:
    image: hyperledger/fabric-couchdb:x86_64-0.4.6
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    ports:
      - ${port1}:5984
    volumes:
      - couchdb${COUCH_ID}.${CORG}:/opt/couchdb/data
    hostname: couchdb${COUCH_ID}.${CORG}
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - couchdb${COUCH_ID}.${CORG}
EOF
}
#addCouch 2 1000 ext org1