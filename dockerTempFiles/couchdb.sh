#!/bin/bash

DTSPATH="./services.yaml"
function addCouch() {
    COUCH_ID=$1
    AddNumber=$2
    port1=$(expr 5984 + $2)
    EXTERNAL_NETWORK=$3
    CORG=$4
    d_type="$5"
if [ "$d_type" != "Docker-compose" ]; then
cat << EOF >> ${DTSPATH}
  couchdb${COUCH_ID}_${CORG}:
    image: hyperledger/fabric-couchdb:0.4.14
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    hostname: couchdb${COUCH_ID}.${CORG}
EOF
else
cat << EOF >> ${DTSPATH}
  couchdb${COUCH_ID}.${CORG}:
    image: hyperledger/fabric-couchdb:0.4.14
    container_name: couchdb${COUCH_ID}.${CORG}
EOF
fi
cat << EOF >> ${DTSPATH}
    ports:
      - ${port1}:5984
    volumes:
      - couchdb${COUCH_ID}.${CORG}:/opt/couchdb/data
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - couchdb${COUCH_ID}.${CORG}
EOF
}
#addCouch 2 1000 ext org1