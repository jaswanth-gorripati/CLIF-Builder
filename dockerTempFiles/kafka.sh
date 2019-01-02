#!/bin/bash

function addKafka() {
    KF_ID=$1
    AddNumber=$2
    port1=$(expr 5984 + $2)
    EXTERNAL_NETWORK=$3
    PATHZ=$4
    zoo_str=$5
    Zoo_count=$6
    cat << EOF >> ${PATHZ}
  kafka${KF_ID}:
    image: hyperledger/fabric-kafka:x86_64-0.4.6
    hostname: kafka${KF_ID}
    environment:
      - KAFKA_LOG_RETENTION_MS=-1
      - KAFKA_MESSAGE_MAX_BYTES=1000012
      - KAFKA_REPLICA_FETCH_MAX_BYTES=1048576
      - KAFKA_UNCLEAN_LEADER_ELECTION_ENABLE=false
      - KAFKA_DEFAULT_REPLICATION_FACTOR=3
      - KAFKA_MIN_INSYNC_REPLICAS=2
      - KAFKA_BROKER_ID=0
      - KAFKA_ZOOKEEPER_CONNECT=${zoo_str}
      - KAFKA_REPLICA_FETCH_RESPONSE_MAX_BYTES=10485760
    ports:
      - 9092
    depends_on:
EOF
    for zoo in `seq 0 ${Zoo_count}`
    do
        cat << EOF >> ${PATH}
      - zookeeper${zoo}
EOF
    done
    cat << EOF >> ${PATH}
    networks:
      EXTERNAL_NETWORK:
        aliases:
          - kafka${KF_ID}
EOF
}