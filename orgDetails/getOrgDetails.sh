#!/bin/bash
BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
declare -A orgDetails
index=0
count=0

function OrgName () {
    echo -e "${LBLUE}"
    read -p "   Name: " ORGANISATION_NAME
    echo -e "${NC}"
    if [ -z "$ORGANISATION_NAME" ]; then
        echo -e "${RED}!!! Please enter organisation name${NC}"
        OrgName
        return
    fi
    for org in ${ORG[@]}
    do
        if [ "$org" == "$ORGANISATION_NAME" ]; then
            echo -e "${RED}!!! ORGANISATION ALREADY EXISTS, Enter Again${NC}"
            OrgName
            return
        fi
    done
    orgDetails[$count,$index]=$ORGANISATION_NAME
    ORG[$count]=$ORGANISATION_NAME
    # echo "${count},${index}"
    # echo "${orgDetails[@]}" 
}
function PeerCount () {
    if [ "$1" == "" ]; then
        index=$(expr $index + 1)
    else
        index=$1
    fi
    echo -e "${LBLUE}"
    read -p "   Number of peers :  " Peer_count
    echo -e "${NC}"
    if [ -z "$Peer_count" ]; then
        echo "please enter organisation Peer count"
        PeerCount $index
        return;
    fi
    reg='^[1-3]{1}$'
    if [[ ! $Peer_count =~ $reg ]]; then
        echo -e "${RED}!!! Maximum 3 peers can be used${NC}"
        PeerCount $index
        return;
    fi
    orgDetails[$count,$index]=$Peer_count
    # echo "${count},${index}"
    # echo "${orgDetails[@]}"
}
function useCouchDb () {
    if [ "$1" == "" ]; then
        index=$(expr $index + 1)
    else
        index=$1
    fi
    echo -e "${LBLUE}"
    read -p "   Use Couchdb ( y/n ) :" Use_Couchdb
    echo -e "${NC}"
    case $Use_Couchdb in
        y|Y) Use_Couchdb=true;echo $Use_Couchdb;;
        n|N) Use_Couchdb=false;echo $Use_Couchdb;;
        *) echo -e " ${RED}please enter valid response ( y/n )${NC}";useCouchDb $index;return;;
    esac
    orgDetails[$count,$index]=$Use_Couchdb
    # echo "${count},${index}"
    # echo "${orgDetails[@]}"
}
enterDetails() {
    OrgName
    PeerCount
    useCouchDb
}

readDetails() {
    echo -e "${BROWN}"
    read -p "Do you want to add another organisation ( y/n ) " addNewOrg
    echo -e "${NC}"
     case $addNewOrg in
        y|Y) count=$(expr $count + 1);index=0;getOrgDetails;;
        n|N) echo -e "${GREEN}Saving Organisation details${NC}";;
        *) echo -e "${RED}please enter valid response ( y/n ) ${NC}";readDetails;return;;
    esac
}
function getOrgDetails() {
    clear
    echo -e "Enter new organisation details"
    enterDetails
    readDetails
    #echo ${orgDetails[@]}
}
