#!/bin/bash

DTSPATH="./services.yaml"
function addZookeeper() {
    ZOO_ID=$1
    EXTERNAL_NETWORK=$2
    zoo_str=$3
    cat << EOF >> ${DTSPATH}
  zookeeper${ZOO_ID}:
    image: hyperledger/fabric-zookeeper:x86_64-0.4.6
    hostname: zookeeper${ZOO_ID}
    environment:
      - ZOO_MY_ID=$(expr ${ZOO_ID} + 1)
      - ZOO_SERVERS=${zoo_str}
    ports:
      - 2181
      - 2888
      - 3888
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - zookeeper${ZOO_ID}
EOF
}
#addZookeeper 1 ext ./zoo.yaml "server.1 zookeeprr1,server.2 zk 2"