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
    val=$1
    fc=$2
    if [ -z "$val" ]; then
        echo -e "${RED}!!! Please enter a value"
        $fc
        return;
    fi
    reg='^[1-5]{1}$'
    if [[ ! $val =~ $reg ]]; then
        echo -e " ${RED}!!! Maximum 5 Channels can be used${NC}"
        $fc
        return;
    fi
}
readNoOfOrderers() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of Orderers to be used :   " NO_OF_ORDERERS  
    echo -e "${NC}"
    Verify $NO_OF_ORDERERS readNoOfOrderers
}

readKafkaDetails() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of Kafkas to be used : " NO_OF_KAFKAS  
    echo -e "${NC}"
    Verify $NO_OF_KAFKAS readKafkaDetails
}
readZookeeperDetails() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of Zookeepers to be used : " NO_OF_ZOOKEEPERS  
    echo -e "${NC}"
    Verify $NO_OF_ZOOKEEPERS readZookeeperDetails
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
    OCons=("$@")
    echo -e "${LBLUE}"
    read -p "   Enter Consortium to be used in ORDERER : " OCNAME    
    echo -e "${NC}"
    if [ -z "$OCNAME" ]; then
        echo -e "${RED}!!! Please enter a valid Name${NC}"
        readOrdererConsortium "${OCons[@]}"
        return;
    fi
    canAddOCons=false
    for ocons in ${OCons[@]}
    do
        if [ "$ocons" == "$OCNAME" ]; then
            canAddOCons=true
        fi
    done
    if [ $canAddOCons == true ]; then
       ORDERER_CONSORTIUM=$OCNAME
    else
        echo -e "${RED} Consortium name is not recognised .. plese enter from this list [ ${OCons[@]}] }"
        readOrdererConsortium "${OCons[@]}"
        return
    fi
}
