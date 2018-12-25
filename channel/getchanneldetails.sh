#!/bin/bash
BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
No_of_Channels=0
declare -A CHANNELS
CCOUNT=0
CINDEX=0
getNumberOfChannels() {
    echo -e "${LBLUE}"
    read -p "   Enter Number of channels to be used :" No_of_Channels  
    echo -e "${NC}"  
    if [ -z "$No_of_Channels" ]; then
        echo -e "${RED}!!! Please enter a value"
        getNumberOfChannels
        return;
    fi
    reg='^[1-5]{1}$'
    if [[ ! $No_of_Channels =~ $reg ]]; then
        echo -e " ${RED}!!! Maximum 5 Channels can be used${NC}"
        getNumberOfChannels
        return;
    fi
}

readChannelName() {
    echo -e "${BLUE}"
    read -p "   Enter name of  the Channel $1: " CNAME    
    echo -e "${NC}"
    if [ -z "$CNAME" ]; then
        echo -e "${RED}!!! Please enter a valid Name${NC}"
        readChannelName
        return;
    fi
    reg='^[a-z\-]+$'
    if [[ ! $CNAME =~ $reg ]]; then
        echo -e " ${RED}!!! Channel name must contain only small characters${NC}"
        readChannelName
        return;
    fi
    for CNS in ${CNS[@]}
    do
        if [ "$CNS" == "$CNAME" ]; then
            echo -e "${RED}!!! CHANNEL NAME ALREADY EXISTS, Enter Again${NC}"
            readChannelName
            return
        fi
    done
    CHANNELS[$CCOUNT,$CINDEX]=$CNAME
    CNS[$CCOUNT]=$CNAME
}

readChannelConsortium() {
    echo -e "${BLUE}"
    read -p "   Enter Consortium to be used in Channel ${CNS[$CCOUNT]} : " CCNAME    
    echo -e "${NC}"
    if [ -z "$CCNAME" ]; then
        echo -e "${RED}!!! Please enter a valid Name${NC}"
        readChannelName
        return;
    fi
    canAddCons=false
    for cons in ${cCons[@]}
    do
        if [ "$cons" == "$CCNAME" ]; then
            canAddCons=true
        fi
    done
    if [ $canAddCons == true ]; then
        CHANNELS[$CCOUNT,$CINDEX]=$CCNAME
    else
        echo -e "${RED} COnsortium name is not recognised .. plese enter from this list [ ${cCons[@]} ]${NC}"
        readChannelConsortium
        return
    fi
    #echo ${CHANNELS[@]}
}

readOrgsInChannel() {
    if [ "$1" == "" ]; then
        CINDEX=$(expr $CINDEX + 1)
    else
        CINDEX=$1
    fi
    echo -e "${BLUE}"
    read -p "   Enter the organisation $(expr ${CINDEX} - 3) in CHANNEL $CCOUNT: " ORG_NAME    
    if [ -z "$ORG_NAME" ]; then
        echo -e "${RED}!!!  Please enter organisation$(expr ${CINDEX} - 3) name for this CHANNEL${NC}"
        readOrgsInChannel ${CINDEX}
        return;
    fi
    canAdd=false
    for org in ${cOrgs[@]}
    do
        if [ "$org" == "$ORG_NAME" ]; then
            canAdd=true
        fi
    done
    for CHORG in ${CHORGS[@]}
    do
        if [ "$CHORG" == "$ORG_NAME" ]; then
            echo -e "${RED}!!! CANNOT USE ORG NAME TWICE ${NC}"
            readOrgsInChannel ${CINDEX}
            return
        fi
    done
    if [ $canAdd == false ]; then
        echo -e "${RED}Please enter a valid organisation from ${BROWN}[ ${cOrgs[@]} ] ${NC}"
        readOrgsInChannel ${CINDEX}
        return;
        #break;
    fi
    CHANNELS[$CCOUNT,$CINDEX]=$ORG_NAME
    CHORGS[$(expr ${CINDEX} - 2)]=$ORG_NAME
    if [ $( expr ${#cOrgs[@]}) == $( expr ${#CHORGS[@]} - 1 ) ]; then
        echo -e "${LBLUE}ALL ORGANISATIONS ARE ADDED IN THE CONSORTIUM${NC}"
        CHANNELS[$CCOUNT,2]=$(expr ${CINDEX} - 2)
        return
    else   
        addCOrg
    fi
}
addCOrg() {
    echo -e "${BROWN}"
    read -p "Add organisation  to the Channel ( y/n ) :  " add_COrg
    echo -e "${NC}"
    case $add_COrg in
        y|Y) add_Org=true;readOrgsInChannel;;
        n|N) add_Org=false; CHANNELS[$CCOUNT,2]=$(expr ${CINDEX} - 2);;
        *) echo -e " ${RED}please enter valid response ( y/n )${NC}";addCOrg;return;;
    esac
}

readChannelDetails() {
    for i in `seq 0 $(expr $No_of_Channels - 1)`
    do  
        clear
        CCOUNT=$i
        CINDEX=0
        echo "Getting details of Channel $i"
        readChannelName $CCOUNT
        CINDEX=1
        readChannelConsortium
        CINDEX=3
        CHORGS=("")
        readOrgsInChannel $CINDEX
    done
    echo -e "${NC}"

}

getChannelDetails() {
    clear
    args=("$@")
    for i in `seq 1 ${args[0]}`
    do 
        cOrgs[$(expr $i - 1)]=${args[$i]}
    done
    len=$(expr ${#args[@]})
    for j in `seq ${args[0]} $len`
    do 
        cCons[$(expr $j - ${args[0]})]=${args[$(expr $j + 1)]}
    done
    echo "${cOrgs[@]}"
    echo "${cCons[@]}"

    if [ "$cOrgs" == "" ]; then
        echo "Please pass organisation parameters"
        #exit 0
        return
    fi
    if [ "$cCons" == "" ]; then
        echo "Please pass Consortium parameters"
        #exit 0
    fi
    echo -e "Enter details of the CHANNELS in the network"
    getNumberOfChannels
    readChannelDetails
}