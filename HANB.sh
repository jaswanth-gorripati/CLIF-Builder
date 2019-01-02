#!/usr/bin/env bash

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
. ./consortium/consortium.sh

. ./channel/getchanneldetails.sh

. ./orgTempFiles/crypto-config-temp.sh
. ./orgTempFiles/configtx-temp.sh
. ./orderer/getordererdetails.sh
. ./orgDetails/getOrgDetails.sh
LBLUE='\033[1;34m'
BLUE='\033[0;34m'
CYAN='\033[1;30m'
NC='\033[0m'
GREEN='\033[0;32m'
ESC=$(printf "\033")


function askProceed () {
  echo -e "${BROWN}"
  read -p "Continue To generate certificates and network (y/n) ? " ans
  case "$ans" in
    y|Y )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}
function select_option {
  
  # little helpers for terminal print control and key input
  cursor_blink_on()  { printf "%s" "${ESC}[?25h"; }
  cursor_blink_off() { printf "%s" "${ESC}[?25l"; }
  cursor_to()        { printf "%s" "${ESC}[$1;${2:-1}H"; }
  print_option()     { printf "${BLUE}%s${NC}" "   $1 "; }
  print_selected()   { printf "${BLUE}> %s${NC}""${ESC}[1;34m $1 ${ESC}[0m"; }
  get_cursor_row()   { IFS=';' read -rsdR -p $'\E[6n' ROW COL; echo "${ROW#*[}"; echo "$COL" > /dev/null; }
  key_input()        {
    read -rs -n3 key 2>/dev/null >&2
    if [[ $key = ${ESC}[A ]]; then echo "up"; fi
    if [[ $key = ${ESC}[B ]]; then echo "down"; fi
    if [[ $key = "" ]]; then echo "enter"; fi
  }

  # initially print empty new lines (scroll down if at bottom of screen)
  # for opt; do printf "\n"; done

  # determine current screen position for overwriting the options
  # local lastrow=$(expr `get_cursor_row` + 1)
  # echo $lastrow
  # local startrow=$(($lastrow - $#))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo 2> /dev/null; clear; exit" 2
  cursor_blink_off

  local selected=1
  local title="$1"
  shift

  while true; do
    clear
    printf "%s" "$title"
    # print options by overwriting the last lines
    local idx=1
    for opt; do
      cursor_to $((idx + 1))
      #cursor_to $lastrow
      #INX=$(expr "$lastrow" + "$idx")
      if [ $idx -eq $selected ]; then
        print_selected "$opt"
      else
        print_option "$opt"
      fi
      ((idx++))
    done

    # user key control
    case $(key_input) in
      enter) break;;
      up)    ((selected--));
        if [ $selected -lt 1 ]; then selected=$(($#)); fi
      ;;
      down)  ((selected++));
        if [ $selected -gt $# ]; then selected=1; fi
      ;;
    esac
  done

  # cursor position back to normal
  printf "\n"
  cursor_blink_on

  return $((selected - 1))
}

function gConfigFile() {
  ORG_NAME=${orgDetails[0,0]}
  setOrg $ORG_NAME
  orderer_tpe=$(echo "$ORDERER_TYPE" | awk '{print tolower($0)}')
  ctxFile
  ctxOrgaizations ${ORG_NAME}
  #
  # N E E D    T O    W O R K    O N    M U L T I P L E   O R G S 
  #
  # ctxaddAllOrgs "org2"
  # ctxaddAllOrgs "org3"
  # ctxaddAllOrgs "org4"
  ctxOrderer ${orderer_tpe} ${NO_OF_ORDERERS} ${NO_OF_KAFKAS}
  ctxGenesisProfile ${ORG_NAME} ${orderer_tpe} ${NO_OF_ORDERERS}
  # arr=( "Cons1" "2" "org1" "org2" )
  # ctxAddConsor ${arr[@]}
  ctxChannelProfile ${CHANNELS[0,0]} ${ORG_NAME}
  # arr2=( "myc" "Cons1" "2" "org1" "org2" )
  # ctxAllChannels ${arr2[@]}
  ctxCapabilities
}

function gCryptoConfig() {
  OC=$( expr ${#orgDetails[@]} / 3)
  MX=$(expr $OC - 1)
  for inx in `seq 0 $MX`
  do
    if [ "${inx}" == "0" ]; then
      case $ORDERER_TYPE in
      "SOLO") gCryptoPeers ${orgDetails[${inx},0]} ${orgDetails[${inx},1]} "true" $ORDERER_TYPE;;
      "KAFKA") gCryptoPeers ${orgDetails[${inx},0]} ${orgDetails[${inx},1]} "true" $ORDERER_TYPE $NO_OF_ORDERERS;;
    esac
    else
      gCryptoPeers ${orgDetails[${inx},0]} ${orgDetails[${inx},1]} "false"
    fi
  done
    
}


arrOrgDetails() {
    #echo $1
    OCNT=$( expr ${#orgDetails[@]} / 3)
    max=$(expr $OCNT - 1)
    echo -e "${GREEN}"
    echo -e "Organisations list${NC}"
    for lf in `seq 0 $max`
    do
      #ORG[${lf}]=${orgDetails[${lf},0]}
      #echo "$(tput bel )"
      echo -e " ${LBLUE}Organisation ${lf} : ${NC}"
      echo -e "    ${BLUE}Name             : ${orgDetails[${lf},0]}"
      echo -e "    Peers count      : ${orgDetails[${lf},1]}"
      echo -e "    Is using CouchDb : ${orgDetails[${lf},2]} ${NC}"
        
    done
    #echo ${ORG[@]}
}
arrCons() {
  #echo "IN"
  Cons=$( expr ${#CON[@]} - 1)
  echo -e "${GREEN}"
  echo -e "CONSORTIUMS list${NC}"
  for con in `seq 0 ${Cons}`
  do
    #ORG[${lf}]=${orgDetails[${lf},0]}
    #echo "$(tput bel )"
    echo -e " ${LBLUE}CONSORTIUMS ${con} : ${NC}"
    echo -e "    ${BLUE}Name                   : ${CONSORTIUMS[${con},0]}"
    echo -e "    ORGANISATIONS INVOLVED : "
    for org in `seq 2 $(expr ${CONSORTIUMS[${con},1]} + 1)`
    do
    echo -e "    ${BLUE}                ${CONSORTIUMS[${con},${org}]} ${NC}"
    done
  done
}
arrChnls() {
  #echo "IN"
  Cns=$( expr ${#CNS[@]} - 1)
  echo -e "${GREEN}"
  echo -e "CHANNEL list${NC}"
  for cn in `seq 0 ${Cns}`
  do
    #ORG[${lf}]=${orgDetails[${lf},0]}
    #echo "$(tput bel )"
    echo -e " ${LBLUE}CHANNEL ${cn} : ${NC}"
    echo -e "    ${BLUE}Name                     : ${CHANNELS[${cn},0]}"
    echo -e "    ${BLUE}CONSORTIUM USED          : ${CHANNELS[${cn},1]}"
    echo -e "    ORGANISATIONS INVOLVED   : "
    #echo $(expr ${CHANNELS[${cn},2]} + 1)
    for orgs in `seq 3 $(expr ${CHANNELS[${cn},2]} + 2)`
    do
    echo -e "      ${BLUE}                ${CHANNELS[${cn},${orgs}]} ${NC}"
    done
  done
}
printOrderer() {
  echo -e "${GREEN}ORDERER DETAILS: "
  echo ""
  echo -e "${BLUE}      Type                     : $ORDERER_TYPE"
  echo -e "${BLUE}      Consortium in  Orderers  : $ORDERER_CONSORTIUM${NC}"
  echo -e "${BLUE}      Number Of Orderers       : $NO_OF_ORDERERS${NC}"
  if [ "$ORDERER_TYPE" == "KAFKA" ]; then
  echo -e "${BLUE}      Number Of KAFKAS         : $NO_OF_KAFKAS${NC}"
  echo -e "${BLUE}      Number Of Zookeepers     : $NO_OF_ZOOKEEPERS${NC}"
  fi
}
yourConfig() {
  echo -e "${BROWN}Your Network configuration ↓${NC}"
  arrOrgDetails
  arrCons
  arrChnls
  printOrderer
  askProceed
  gCryptoConfig
  gConfigFile

}
getOrdererDetails() {
  ORDERER_TYPE="$1"
  if [ "$ORDERER_TYPE" == "SOLO" ]; then
    NO_OF_ORDERERS=1
    readOrdererConsortium "${CON[@]}"
    #printOrderer
  else
    readOrdererConsortium "${CON[@]}"
    readNoOfOrderers
    readKafkaDetails
    readZookeeperDetails
    #printOrderer
  fi
  yourConfig
}
readOrdererType() {
  Orderer_type=$(select_opt "Select the Orderer type to work on : " "SOLO" "KAFKA")
  case "$Orderer_type" in
    0) getOrdererDetails "SOLO";;
    1) getOrdererDetails "KAFKA";;
  esac
}
function getChDetails() {
  getChannelDetails "${#ORG[@]}" "${ORG[@]}" "${CON[@]}"
  arrChnls
  clear
  readOrdererType
}
function getCons() {
  #echo "Getting consortium"
  getConsortium "${ORG[@]}"
  arrCons
  #echo "${ORG[@]}"
  getChDetails
}
function OrgDetails {
  getOrgDetails
  #echo ${orgDetail[@]}
  COUNT=$( expr ${#orgDetails[@]} / 3)
  # echo "length = $(expr $COUNT)"
  #echo "${ORG[@]}"
  arrOrgDetails $(expr $COUNT - 1)
  sleep 5
  getCons
}
function installPreRequirements {
  echo  -e "${GREEN}installing Pre-requirements${NC}"
  #sleep 10
  OrgDetails
}
function needToInstallPreRequirements {
  insP=$(select_opt "Do you want to install all Prerequirements ?" "YES" "NO" )
  case "$insP" in 
    0) installPreRequirements ;;
    1) echo "Assuming Prerequirements  are installed";OrgDetails;;
  esac
}
function networkSelected {
  echo  -e "${GREEN} YOu selected Fabric $1 version${NC}"
  #sleep 10
  needToInstallPreRequirements
}

function orderertype {
 select_option "$@" 1>&2
  local result=$?
  #echo $result  
}

function dbselection {
  select_option "$@" 1>&2
  local result=$?
  echo $result
}

function select_opt {
  select_option "$@" 1>&2
  local result=$?
  echo $result
}

function versions {
  select_option "$@" 1>&2
  local result=$?
  echo $result
}

userChoice=$(select_opt "Select the Hyperledger-fabric version to work on :" "v1.1" "v1.2" "v1.3" "v1.4" )
# clear
case "$userChoice" in
  0) networkSelected "v1.1";;
  1) networkSelected "v1.2";;
  2) networkSelected "v1.3";;
  3) networkSelected "v1.4";;
esac


case "$ordererlist" in 
  0) echo "selected kafka";;
  1) echo "selected solo";; 
esac


case "$dblist" in 
  0) echo "selected couchdb";;
  1) echo "selected leveldb";; 
esac



case "$versionlist" in 
  0) echo "selected 1.1";;
  1) echo "selected 1.2";;
  2) echo "selected 1.3";;
  3) echo "selected 1.4";; 
esac