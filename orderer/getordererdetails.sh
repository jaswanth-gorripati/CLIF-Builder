#!/bin/bash
BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
NO_OF_ORDERERS=0
NO_OF_KAFKAS=0
NO_OF_ZOOKEEPERS=0
ORDERER_CONSORTIUM=""
ORDERER_PROFILENAME=""

Verify() {
    #echo $@
    val=$1
    fc=$2
    OT=$4
    if [ "$val" == "" ]; then
        echo -e "${RED}!!! Please enter a value${NC}"
        $fc $OT
        return;
    fi
    if [ "$OT" == "RAFT" ]; then
        reg='^[3,5]{1}$'
    else
        reg='^[1-5]{1}$'
    fi
    if [[ ! $val =~ $reg ]]; then
        if [ "$OT" == "RAFT" ]; then
            echo -e " ${RED}!!! Only 5 or 3 ${3} can be used${NC}"
        else
            echo -e " ${RED}!!! Maximum 5 ${3} can be used${NC}"
        fi
        $fc $OT
        return;
    fi
}
readNoOfOrderers() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of Orderers to be used :   " NO_OF_ORDERERS  
    echo -e "${NC}"
    #echo "$NO_OF_ORDERER"
    Verify "${NO_OF_ORDERERS}" "readNoOfOrderers" "Orderers" $1
}

readKafkaDetails() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of Kafkas to be used : " NO_OF_KAFKAS  
    echo -e "${NC}"
    Verify "${NO_OF_KAFKAS}" readKafkaDetails "Kafkas"
}
readZookeeperDetails() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of Zookeepers to be used : " NO_OF_ZOOKEEPERS  
    echo -e "${NC}"
    Verify "$NO_OF_ZOOKEEPERS" readZookeeperDetails "Zookeeper"
}

readOrdererProfileName() {
    echo -e "${LBLUE}"
    read -p "   Enter Orderer Profile name to be used in network : " ORDERER_PROFILENAME    
    echo -e "${NC}"
    if [ -z "$ORDERER_PROFILENAME" ]; then
        echo -e "${RED}!!! Please enter a valid Name${NC}"
        readOrdererProfileName
        return;
    fi
    reg='^[a-zA-Z]+$'
    if [[ ! $ORDERER_PROFILENAME =~ $reg ]]; then
        echo -e " ${RED}!!! Orderer profile name should contain only Alphabets ${NC}"
        readOrdererProfileName
        return;
    fi
}

readOrdererConsortium() {
    #
    ## U N C O M M E N T    F O R    C O N S O R T I U M 
    #
    # OCons=("$@")
    # echo -e "${LBLUE}"
    # read -p "   Enter Consortium to be used in ORDERER : " OCNAME    
    # echo -e "${NC}"
    # if [ -z "$OCNAME" ]; then
    #     echo -e "${RED}!!! Please enter a valid Name${NC}"
    #     readOrdererConsortium "${OCons[@]}"
    #     return;
    # fi
    # canAddOCons=false
    # for ocons in ${OCons[@]}
    # do
    #     if [ "$ocons" == "$OCNAME" ]; then
    #         canAddOCons=true
    #     fi
    # done
    # if [ $canAddOCons == true ]; then
    #    ORDERER_CONSORTIUM=$OCNAME
    # else
    #     echo -e "${RED} Consortium name is not recognised .. plese enter from this list [ ${OCons[@]}] }"
    #     readOrdererConsortium "${OCons[@]}"
    #     return
    # fi
    ORDERER_CONSORTIUM="SampleConsortium"
}
