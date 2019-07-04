#!/bin/bash

. ./details.sh

function addVolumes() {
    if [ ${DOCKER_NETWORK_TYPE} == "DOCKER-COMPOSE" ]; then
        echo "version: '2'"
    else
        echo "version: '3'"
    fi
    echo "volumes:"
    for peerCount in `seq 0 $(expr ${NUM_PEERS} - 1)`
    do
        echo "  peer${peerCount}.${ORG}.${DOMAIN}:"
        
        if [ "${USE_COUCHDB}" == "true" ]; then
            echo "  couchdb${peerCount}.${ORG}.${DOMAIN}:"
        fi
    done
    if [ "${IS_ORDERER_ORG}" == "true" ]; then
        for ordererCount in `seq 0 $(expr ${NUM_ORDERERS} - 1)`
        do
            echo "  orderer${ordererCount}.${ORG}.${DOMAIN}:"
        done
        if [ "${ORDERER_TYPE}" == "kafka" ]; then
            for kafkaCount in `seq 0 $(expr ${NUM_KAFKAS} - 1)`
            do
                echo "  kafka${kafkaCount}.${ORG}.${DOMAIN}:"
            done
            for zkCount in `seq 0 $(expr ${NUM_ZOOKEEPERS} - 1)`
            do
                echo "  zookeeper${zkCount}.${ORG}.${DOMAIN}:"
            done
        fi
    fi
    echo "  rca.${ORG}.${DOMAIN}:"
    if [ "${USE_ICA}" == "true" ]; then
        echo "  ica.${ORG}.${DOMAIN}:"
    fi
}

addVolumes