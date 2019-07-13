#!/bin/bash
BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
No_of_consortiums=0
declare -A CONSORTIUMS
COUNT=0
INDEX=0

readNOC() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of consortiums to be used :" No_of_consortiums  
    echo -e "${NC}"  
    if [ -z "$No_of_consortiums" ]; then
        echo -e "${RED}!!! Please enter a value"
        readNOC
        return;
    fi
    reg='^[1-5]{1}$'
    if [[ ! $No_of_consortiums =~ $reg ]]; then
        echo -e " ${RED}!!! Maximum 5 consortiums can be used${NC}"
        readNOC
        break;
    fi
}
getConName() {
    echo -e "${BLUE}"
    read -p "   Enter name of  the consortium $1: " NAME    
    echo -e "${NC}"
    if [ -z "$NAME" ]; then
        echo -e "${RED}!!! Please enter a valid Name${NC}"
        getConName
        return;
    fi
    for con in ${CON[@]}
    do
        if [ "$con" == "$NAME" ]; then
            echo -e "${RED}!!! CONSORTIUM NAME ALREADY EXISTS, Enter Again${NC}"
            getConName
            return
        fi
    done
    CONSORTIUMS[$COUNT,$INDEX]=$NAME
    CON[$COUNT]=$NAME
}
getconOrgs() {
    if [ "$1" == "" ]; then
        INDEX=$(expr $INDEX + 1)
    else
        INDEX=$1
    fi
    echo -e "${BLUE}"
    read -p "   Enter the organisation $(expr ${INDEX} - 2) in consortiums $COUNT: " ORG_NAME    
    if [ -z "$ORG_NAME" ]; then
        echo -e "${RED}!!!  Please enter organisation$(expr ${INDEX} - 2) name for this consortium${NC}"
        getconOrgs ${INDEX}
        return;
    fi
    canAdd=false
    for org in ${ORGS[@]}
    do
        if [ "$org" == "$ORG_NAME" ]; then
            canAdd=true
        fi
    done
    for CONORG in ${CONORGS[@]}
    do
        if [ "$CONORG" == "$ORG_NAME" ]; then
            echo -e "${RED}!!! CANNOT USE ORG NAME TWICE ${NC}"
            getconOrgs ${INDEX}
            return
        fi
    done
    if [ $canAdd == false ]; then
        echo -e "${RED}Please enter a valid organisation from ${ORGS[@]} this list ${NC}"
        getconOrgs ${INDEX}
        return;
        #break;
    fi
    CONSORTIUMS[$COUNT,$INDEX]=$ORG_NAME
    CONORGS[$(expr ${INDEX} - 2)]=$ORG_NAME
    if [ $( expr ${#ORGS[@]}) == $( expr ${#CONORGS[@]}) ]; then
        echo -e "${LBLUE}ALL ORGANISATIONS ARE ADDED IN THE CONSORTIUM${NC}"
        CONSORTIUMS[$COUNT,1]=$(expr ${INDEX} - 1)
    else   
        addOrg
    fi
}
addOrg() {
    echo -e "${BROWN}"
    read -p "Add organisation  to the consortium ( y/n ) :  " add_Org
    echo -e "${NC}"
    case $add_Org in
        y|Y) add_Org=true;getconOrgs;;
        n|N) add_Org=false; CONSORTIUMS[$COUNT,1]=$(expr ${INDEX} - 1);;
        *) echo -e " ${RED}please enter valid response ( y/n )${NC}";addOrg;return;;
    esac
}

getconDetails() {
    for i in `seq 0 $(expr $No_of_consortiums - 1)`
    do  
        clear
        COUNT=$i
        INDEX=0
        echo "Getting details of consortium $i"
        getConName $COUNT
        INDEX=2
        CONORGS=("")
        getconOrgs $INDEX
    done
    echo -e "${NC}"
}
function getConsortium() {
    clear
    ORGS=("$@")
    #echo "${ORGS[@]}"
    if [ "$ORGS" == "" ]; then
        echo "Please pass organisation parameters"
        #exit 0
    fi
    echo -e "Enter details of the CONSORTIUMS in the network"
    readNOC
    getconDetails
}