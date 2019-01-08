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
CPWD=~/HANB
SELECTED_NETWORK_TYP=""
DPath=""
DTVPATH="./volume.yaml"
DTSPATH="./services.yaml"
DTNPATH="./network.yaml"

function addDockerFile() {
    #rm $DTNPATH $DTSPATH $DTVPATH
    echo "$@"
    IS_F_ORG=${15}
    echo $IS_F_ORG
    pport=$9
    SELECTED_NETWORK_TYP=$1
    EX_NTW=$3
    MNUMBER=$4
    addVersion ${SELECTED_NETWORK_TYP}
    addVolumes

    DORG_NAME=$5
    DPEER_COUNT=$6

    DPath="${CPWD}/${DORG_NAME}/docker-compose.yaml"

    addPeerVolumes $DPEER_COUNT $DORG_NAME
    createServiceFile
    D_IS_ORDERER=$8
    if [ "${D_IS_ORDERER}" == "true" ];then 
        D_ORDERER_TYPE=${10}
        D_ORDERER_COUNT=${11}
        D_ORDERER_PN=${12}

        addOrdererVolumes $D_ORDERER_COUNT
        D_ORDERER_TYPE=$(echo "$D_ORDERER_TYPE" | awk '{print tolower($0)}')
        echo ${D_ORDERER_TYPE}
        if [ ${D_ORDERER_TYPE} == "kafka" ]; then
            D_KF_COUNT=${13}
            #echo $D_KF_COUNT
            D_ZOO_COUNT=${14}

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
                KF_ZOO_STR="${KF_ZOO_STR}zookeeper${zoo_cnt}:2181,"
            done
            ZOO_STRING=${ZOO_STRING::-1}
            #echo ${ZOO_STRING}
            #
            ## K A F K A   S T R I N G   
            #
            echo $D_KF_COUNT
            #echo "$(expr $D_ZOO_COUNT - 1)""
            for zoo_cnt in `seq 0 $D_ZOO_COUNT`
            do
                addZookeeper $zoo_cnt $EX_NTW "${ZOO_STRING}"
            done
            KF_ZOO_STR=${KF_ZOO_STR::-1}

            for kf_cnt in `seq 0 $D_KF_COUNT`
            do
                KF_STRING="${KF_STRING}kafka${kf_cnt}:9092,"
                addKafka $kf_cnt $MNUMBER $EX_NTW $KF_ZOO_STR $D_ZOO_COUNT
            done
            KF_STRING=${KF_STRING::-1}
            KF_STRING="${KF_STRING}]"
            for Ocnt in `seq 0 $(expr $D_ORDERER_COUNT - 1)`
            do
                addOrderer $Ocnt $MNUMBER $EX_NTW $D_ORDERER_PN $KF_STRING $D_KF_COUNT
                MNUMBER=$(expr $MNUMBER + 1000)
            done
        else
            for Ocnt in `seq 0 $(expr $D_ORDERER_COUNT - 1)`
            do
                addOrderer $Ocnt $MNUMBER $EX_NTW $D_ORDERER_PN
                MNUMBER=$(expr $MNUMBER + 1000)
            done
        fi
    fi
    addCa $DORG_NAME $MNUMBER $EX_NTW

    D_IS_COUCH=$7
    if [ $D_IS_COUCH == true ];then 
        addCouchVolumes $DPEER_COUNT $DORG_NAME
        for pcnt in `seq 0 $(expr $DPEER_COUNT - 1)`
        do  
            addCouch $pcnt $pport $EX_NTW $DORG_NAME
            addPeer $DORG_NAME $pcnt $pport $EX_NTW true
            pport=$(expr $pport + 1000)
        done
    else
        for pcnt in `seq 0 $(expr $DPEER_COUNT - 1)`
        do  
            addPeer $DORG_NAME $pcnt $pport $EX_NTW false
            pport=$(expr $pport + 1000)
        done
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
if [ "${IS_F_ORG}" == "true" ];then 
    networkFile=$(cat ./mainOrgScripts/generateCrypto.sh)
    DOC_FILE=$(cat ./mainOrgScripts/dockerSetup.sh)
    DPath="${CPWD}/${DORG_NAME}/dockerSetup.sh"
    cat << EOF > ${DPath}
${DOC_FILE}
EOF
    BUILD_FILE=$(cat ./mainOrgScripts/buildingNetwork.sh)
    DPath="${CPWD}/${DORG_NAME}/buildingNetwork.sh"
    cat << EOF > ${DPath}
${BUILD_FILE}
EOF
else
    networkFile=$(cat ./subOrgScripts/generateCrypto.sh)
fi
DPath="${CPWD}/${DORG_NAME}/generateCrypto.sh"
cat << EOF > ${DPath}
${networkFile}
EOF
}
#addDockerFile "Docker-swarm-m" 2 e 0 q 1 true true KAFKA 2 qwe 2 2

