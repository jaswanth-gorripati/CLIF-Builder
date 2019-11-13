#!/bin/bash

DTSPATH="./services.yaml"
function addZookeeper() {
    ZOO_ID=$1
    EXTERNAL_NETWORK=$2
    zoo_str=$3
    d_type="$4"
    cat << EOF >> ${DTSPATH}
  zookeeper${ZOO_ID}:
    image: hyperledger/fabric-zookeeper:0.4.15
EOF
if [ "$d_type" != "Docker-compose" ]; then
cat << EOF >> ${DTSPATH}
    hostname: zookeeper${ZOO_ID}
EOF
else
cat << EOF >> ${DTSPATH}
    container_name: zookeeper${ZOO_ID}
EOF
fi
cat << EOF >> ${DTSPATH}
    environment:
      - ZOO_MY_ID=$(expr ${ZOO_ID} + 1)
      - ZOO_SERVERS=${zoo_str}
    ports:
      - 2181
      - 2888
      - 3888
    volumes:
      - zookeeper${ZOO_ID}.data:/data
      - zookeeper${ZOO_ID}.datalog:/datalog
    networks:
      ${EXTERNAL_NETWORK}:
        aliases:
          - zookeeper${ZOO_ID}
EOF
}
#addZookeeper 1 ext "server.1 zookeeprr1,server.2 zk 2"