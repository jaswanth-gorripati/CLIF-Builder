#!/bin/bash

function addCouch() {
    COUCH_ID=$1
    AddNumber=$2
    port1=$(expr 5984 + $2)
    EXTERNAL_NETWORK=$3
    PATHC=$4
    cat << EOF >> ${PATHC}
  couchdb${COUCH_ID}:
    image: hyperledger/fabric-couchdb:x86_64-0.4.6
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    ports:
      - ${port1}:5984
    hostname: couchdb${COUCH_ID}
    networks:
      EXTERNAL_NETWORK:
        aliases:
          - couchdb${COUCH_ID}
EOF
}