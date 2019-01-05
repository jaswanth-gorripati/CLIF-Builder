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
. ./network.sh

#
##  C O L O R S     F O R      T E R M I N A L 
#
BROWN='\033[0;33m'
NC='\033[0m'
GREEN='\033[0;32m'
PWD=~/HANB
SELECTED_NETWORK_TYP=""
DPath=""
DTVPATH="./volume.yaml"
DTSPATH="./services.yaml"
DTNPATH="./network.yaml"

function addDockerFile() {
    #rm $DTNPATH $DTSPATH $DTVPATH
    echo "$@"
    SELECTED_NETWORK_TYP=$1
    EX_NTW=$3
    MNUMBER=$4
    addVersion ${SELECTED_NETWORK_TYP}
    addVolumes

    DORG_NAME=$5
    DPEER_COUNT=$6

    DPath="${PWD}/${DORG_NAME}/docker-compose.yaml"

    addPeerVolumes $DPEER_COUNT $DORG_NAME
    createServiceFile
    addCa $DORG_NAME $MNUMBER $EX_NTW

    D_IS_COUCH=$7
    if [ $D_IS_COUCH == true ];then 
        addCouchVolumes $DPEER_COUNT $DORG_NAME
        for pcnt in `seq 0 $(expr $DPEER_COUNT - 1)`
        do  
            addCouch $pcnt $MNUMBER $EX_NTW $DORG_NAME
            addPeer $DORG_NAME $pcnt $MNUMBER $EX_NTW true
        done
    else
        for pcnt in `seq 0 $(expr $DPEER_COUNT - 1)`
        do  
            addPeer $DORG_NAME $pcnt $MNUMBER $EX_NTW false
        done
    fi

    D_IS_ORDERER=$8
    if [ "${D_IS_ORDERER}" == "true" ];then 
        D_ORDERER_TYPE=$9
        D_ORDERER_COUNT=${10}
        D_ORDERER_PN=${11}

        addOrdererVolumes $D_ORDERER_COUNT
        D_ORDERER_TYPE=$(echo "$D_ORDERER_TYPE" | awk '{print tolower($0)}')
        echo ${D_ORDERER_TYPE}
        if [ ${D_ORDERER_TYPE} == "kafka" ]; then
            D_KF_COUNT=${12}
            #echo $D_KF_COUNT
            D_ZOO_COUNT=${13}

            D_KF_COUNT=$(expr $D_KF_COUNT - 1)
            D_ZOO_COUNT=$(expr $D_ZOO_COUNT - 1)
            addKafkaVolumes $D_KF_COUNT
            addZookeeperVolumes $D_ZOO_COUNT
            KF_STRING="["
            ZOO_STRING=""
            KF_ZOO_STR=""
            #
            ## Z O O K E E P E R   S T R I N G   
            #
            for zoo_cnt in `seq 0 ${D_ZOO_COUNT}`
            do
                ZOO_STRING="${ZOO_STRING}server.$(expr $zoo_cnt + 1)=zookeeper${zoo_cnt}:2888:3888 "
                KF_ZOO_STR="zookeeper${zoo_cnt}:2181,"
            done
            ZOO_STRING=${ZOO_STRING::-1}
            #
            ## K A F K A   S T R I N G   
            #
            echo $D_KF_COUNT
            #echo "$(expr $D_ZOO_COUNT - 1)""
            for zoo_cnt in `seq 0 $D_ZOO_COUNT`
            do
                addZookeeper $zoo_cnt $EX_NTW $ZOO_STRING
            done
            KF_ZOO_STR=${KF_ZOO_STR::-1}

            for kf_cnt in `seq 0 $D_KF_COUNT`
            do
                KF_STRING="${KF_STRING}kafka${kf_cnt}:9092"
                addKafka $kf_cnt $MNUMBER $EX_NTW $KF_ZOO_STR $D_ZOO_COUNT
            done
            KF_STRING="${KF_STRING}]"
            for Ocnt in `seq 0 $(expr $D_ORDERER_COUNT - 1)`
            do
                addOrderer $Ocnt $MNUMBER $EX_NTW $D_ORDERER_PN $KF_STRING $D_KF_COUNT
            done
        else
            for Ocnt in `seq 0 $(expr $D_ORDERER_COUNT - 1)`
            do
                addOrderer $Ocnt $MNUMBER $EX_NTW $D_ORDERER_PN
            done
        fi
    fi
    addCli $DORG_NAME $EX_NTW
    addNetwork $EX_NTW
    createTempFile
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
    cat << EOF > ${DPath}
${volumeFile}
${servicesFile}
${networkFile}
EOF
rm ${DTVPATH} ${DTSPATH} $DTNPATH
}
#addDockerFile "Docker-swarm-m" 2 e 0 q 1 true true KAFKA 2 qwe 2 2

