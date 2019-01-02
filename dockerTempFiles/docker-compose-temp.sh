#!/bin/bash

#
##  I M P O R T S 
#
. ./volumes.sh
. ./ca.sh
. ./cli.sh
. ./couchdb.sh
. ./kafka.sh
. ./orderer.sh
. ./peer.sh
. ./zookeeper.sh

#
##  C O L O R S     F O R      T E R M I N A L 
#
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
PWD=~/HANB
SELECTED_NETWORK_TYPE=""
DPath=""
DTVPATH="./volume.yaml"
DTSPATH="./services.yaml"
DTNPATH="./network.yaml"

function addDockerFile() {
    SELECTED_NETWORK_TYPE=$1
    EX_NTW=$3
    MNUMBER=$4
    addVersion
    addVolumes

    DORG_NAME=$4
    DPEER_COUNT=$5

    DPath="${PWD}/${DORG_NAME}/docker-compose.yaml"

    addPeerVolumes $DPEER_COUNT $DORG_NAME
    createServiceFile
    addCa $DORG_NAME $MNUMBER $EX_NTW

    D_IS_COUCH=$6
    if [ ${D_IS_COUCH} == true ];then 
        addCouchVolumes $DPEER_COUNT $DORG_NAME
        for pcnt in 'seq 0 $(expr ${DPEER_COUNT} - 1'
        do  
            addCouch $pcnt $MNUMBER $EX_NTW $DORG_NAME
            addPeer $DORG_NAME $pcnt $MNUMBER $EX_NTW true
        done
    else
        addPeer $DORG_NAME $pcnt $MNUMBER $EX_NTW false
    fi

    D_IS_ORDERER=$7
    if [ ${D_IS_ORDERER} == true ];then 
        D_ORDERER_TYPE=$8
        D_ORDERER_COUNT=$9
        D_ORDERER_PN=${10}

        addOrdererVolumes $D_ORDERER_COUNT

        if [ ${D_ORDERER_TYPE} == "kafka" ]; then
            D_KF_COUNT=${11}
            D_ZOO_COUNT=${12}

            addKafkaVolumes $D_KF_COUNT
            addZookeeperVolumes $D_ZOO_COUNT
            KF_STRING="["
            ZOO_STRING=""
            KF_ZOO_STR=""
            #
            ## Z O O K E E P E R   S T R I N G   
            #
            for zoo_cnt in `seq 0 $(expr $D_ZOO_COUNT - 1)`
            do
                ZOO_STRING="${ZOO_STRING}server.$(expr $zoo_cnt + 1)=zookeeper${zoo_cnt}:2888:3888 "
                KF_ZOO_STR="zookeeper${zoo_cnt}:2181,"
            done
            ZOO_STRING=${ZOO_STRING::-1}
            #
            ## K A F K A   S T R I N G   
            #
            for zoo_cnt in `seq 0 $(expr $D_ZOO_COUNT - 1)`
            do
                addZookeeper $zoo_cnt $EX_NTW $ZOO_STRING
            done
            KF_ZOO_STR=${KF_ZOO_STR::-1}

            for kf_cnt in `seq 0 $(expr $D_KF_COUNT - 1)`
            do
                KF_STRING="${KF_STRING}kafka${kf_cnt}:9092"
                addKafka $kf_cnt $MNUMBER $EX_NTW $KF_ZOO_STR $D_ZOO_COUNT
            done
            KF_STRING="${KF_STRING}]"
            for Ocnt in `seq 0 $(expr $D_ORDERER_COUNT - 1)`
            do
                addOrderer $Ocnt $MNUMBER $EX_NTW $D_ORDERER_PN $KF_STRING $(expr $D_KF_COUNT - 1)
            done
        else
            for Ocnt in `seq 0 $(expr $D_ORDERER_COUNT - 1)`
            do
                addOrderer $Ocnt $MNUMBER $EX_NTW $D_ORDERER_PN
            done
        fi
    fi
    addCli $DORG_NAME $EX_NTW
}

function createServiceFile() {
    cat << EOF > ${DTSPATH}
services:
EOF
}

function createTempFile() {
    volumeFile=$(cat ${DTVPATH})
    servicesFile=$(cat ${DTSPATH})
    networkFile=$(cat ${DTNPATH})
    cat << EOF >> ${DPath}
${volumeFile}
${servicesFile}
${networkFile}
EOF
}

