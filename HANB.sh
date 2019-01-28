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
. ./dockerTempFiles/docker-compose-temp.sh
. ./dockerTempFiles/volumes.sh
. ./dockerTempFiles/ca.sh
. ./dockerTempFiles/cli.sh
. ./dockerTempFiles/couchdb.sh
. ./dockerTempFiles/kafka.sh
. ./dockerTempFiles/orderer.sh
. ./dockerTempFiles/peer.sh
. ./dockerTempFiles/zookeeper.sh
. ./dockerTempFiles/network.sh
. ./deployMainNetwork/startMain.sh
. ./endNote.sh
C_P=$PWD


LBLUE='\033[1;34m'
BLUE='\033[0;34m'
CYAN='\033[1;30m'
NC='\033[0m'
GREEN='\033[0;32m'
ESC=$(printf "\033")

OPROT=0
PPORT=0
CPORT=0
declare -A ORGS_SSH



function askProceed () {
  echo -e "${BROWN}"
  read -p "$1" ans
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

declare -A T_ORGS
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
      T_ORGS[${lf}]=${orgDetails[${lf},0]}
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
  echo -e "${BLUE}      Profile Name             : $ORDERER_PROFILENAME"
  echo -e "${BLUE}      Type                     : $ORDERER_TYPE"
  echo -e "${BLUE}      Consortium in  Orderers  : $ORDERER_CONSORTIUM${NC}"
  echo -e "${BLUE}      Number Of Orderers       : $NO_OF_ORDERERS${NC}"
  if [ "$ORDERER_TYPE" == "KAFKA" ]; then
  echo -e "${BLUE}      Number Of KAFKAS         : $NO_OF_KAFKAS${NC}"
  echo -e "${BLUE}      Number Of Zookeepers     : $NO_OF_ZOOKEEPERS${NC}"
  fi
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
  ctxCapabilities
  ctxGenesisProfile ${ORG_NAME} ${orderer_tpe} ${NO_OF_ORDERERS} ${ORDERER_PROFILENAME}
  # arr=( "Cons1" "2" "org1" "org2" )
  # ctxAddConsor ${arr[@]}
  ctxChannelProfile ${CHANNELS[0,0]} ${ORG_NAME}
  # arr2=( "myc" "Cons1" "2" "org1" "org2" )
  # ctxAllChannels ${arr2[@]}
  cf_o_org=$(expr ${#T_ORGS[@]} - 1)
  for conf_cnt in `seq 1 $cf_o_org`
  do
    ORG_NAME=${T_ORGS[$conf_cnt]}
    setOrg $ORG_NAME
    ctxFile
    ctxaddAllOrgs ${T_ORGS[$conf_cnt]}
  done
}

function gCryptoConfig() {
  OC=$( expr ${#orgDetails[@]} / 3)
  MX=$(expr $OC - 1)
  gCleanFolder
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
function readCCver() {
  echo -e "${BLUE}"
    read -p "   Enter chaincode version to install in the network : " CC_VRSN   
    echo -e "${NC}"
  if [ -z "$CC_VRSN" ]; then
      echo -e "${RED}!!! Please enter a chaincode version${NC}"
      readCCver
      return;
  fi
  # reg='^[0]+$'
  # if [[ ! $EXT_NTW_NAME =~ $reg ]]; then
  #     echo -e " ${RED}!!! Network name must contain only Alphabets${NC}"
  #     readNetworkName
  #     return;
  # fi
}
function generateDockerFiles() {
  addDockerFile $SELECTED_NETWORK_TYPE "2" $EXT_NTW_NAME 0 ${orgDetails[0,0]} ${orgDetails[0,1]} ${orgDetails[0,2]} true 0 $ORDERER_TYPE $NO_OF_ORDERERS $ORDERER_PROFILENAME $NO_OF_KAFKAS $NO_OF_ZOOKEEPERS true
  MOPath="${CPWD}/${orgDetails[0,0]}/"
  cd $MOPath
  #source  ./${MOPath
  chmod +x generateCrypto.sh
  ./generateCrypto.sh "./" ${orgDetails[0,0]} $ORDERER_PROFILENAME ${CHANNELS[0,0]}
  cd $C_P
  TNP=${orgDetails[0,1]}
  PPORT=${TNP}000
  OCNT=$( expr ${#orgDetails[@]} / 3)
  max=$(expr $OCNT - 1)
  for DP_CNT in `seq 1 $max`
  do
    #DPath="${CPWD}/${DORG_NAME}/docker-compose.yaml"
    addDockerFile $SELECTED_NETWORK_TYPE "2" $EXT_NTW_NAME ${DP_CNT}000 ${orgDetails[${DP_CNT},0]} ${orgDetails[${DP_CNT},1]} ${orgDetails[${DP_CNT},2]} false $PPORT
    TNP=$(expr $TNP + ${orgDetails[$DP_CNT,1]})
    PPORT=${TNP}000
    MOPath="${CPWD}/${orgDetails[${DP_CNT},0]}/"
    if [ "$SELECTED_NETWORK_TYPE" != "Docker-swarm-m" ]; then
      cd $MOPath
      #source ./${MOPath}
      chmod +x generateCrypto.sh
      ./generateCrypto.sh "./" ${orgDetails[${DP_CNT},0]} ${orgDetails[0,0]}
      cd $C_P
    else
      MOPath="${orgDetails[${DP_CNT},0]}"
      echo -e "Sending Crypto Materials to ${orgDetails[${DP_CNT},0]} organisation which is at ${ORGS_SSH[${orgDetails[${DP_CNT},0]}]}"
      ssh ${ORGS_SSH[${orgDetails[${DP_CNT},0]}]} rm -rf ./HANB/* 
      ssh ${ORGS_SSH[${orgDetails[${DP_CNT},0]}]} mkdir -p HANB/$MOPath 
      scp -r ${CPWD}/$MOPath/* ${ORGS_SSH[${orgDetails[${DP_CNT},0]}]}:./HANB/$MOPath/
      ssh ${ORGS_SSH[${orgDetails[${DP_CNT},0]}]} chmod +x ./HANB/$MOPath/*
      ssh ${ORGS_SSH[${orgDetails[${DP_CNT},0]}]} /bin/bash << EOF
cd ./HANB/$MOPath/;
./generateCrypto.sh "./" ${orgDetails[${DP_CNT},0]} ${orgDetails[0,0]}
EOF
    fi
  done
  echo -e "${BROWN} Docker Files are generated ....${NC}"
  MOPath="${CPWD}/${orgDetails[0,0]}/"
  readCCver
  if [ "${ORDERER_TYPE}" == "KAFKA" ]; then
    ORDR_PRFRD="orderer0"
    else
    ORDR_PRFRD="orderer0"
  fi
  if [ "$SELECTED_NETWORK_TYPE" == "Docker-compose" ]; then
    startComposeNetwork "${CPWD}/${orgDetails[0,0]}/" $EXT_NTW_NAME
    else
    startSwarmNetwork "${CPWD}/${orgDetails[0,0]}/" $EXT_NTW_NAME ${T_ORGS[@]} 
  fi
  echo $PWD
  runMainNetwork "${CPWD}/${orgDetails[0,0]}/" $EXT_NTW_NAME ${CHANNELS[0,0]} ${orgDetails[0,0]} $CC_VRSN $ORDR_PRFRD ${orgDetails[0,1]} $SELECTED_NETWORK_TYPE $STACK_NAME
  ad_cnt=$(expr ${#T_ORGS[@]} - 1)
  for og in `seq 1 $ad_cnt`
  do
    echo "$og"
    if [ "$SELECTED_NETWORK_TYPE" == "Docker-compose" ]; then
      addNewOrg ${T_ORGS[0]} ${T_ORGS[$og]} ${CHANNELS[0,0]} $ORDERER_TYPE ${orgDetails[0,1]}
    else
      addNewOrg ${T_ORGS[0]} ${T_ORGS[$og]} ${CHANNELS[0,0]} $ORDERER_TYPE ${orgDetails[0,1]} $SELECTED_NETWORK_TYPE ${ORGS_SSH[${orgDetails[$og,0]}]}
    fi
    if [ "$og" == "1" ]; then
      updateChannelConfig ${T_ORGS[0]} ${T_ORGS[$og]} ${CHANNELS[0,0]} $SELECTED_NETWORK_TYPE ""
    else
      t_og=$(expr $og - 1)
      tmp=1
      for scn in `seq 1 $t_og`
      do
        m_scn=$(expr $scn - 1)
        echo -e "${BROWN} Sending Update file to ${T_ORGS[$scn]} for signing"
        signChannelConfig ${T_ORGS[$m_scn]} ${T_ORGS[$scn]} ${CHANNELS[0,0]} ${T_ORGS[$og]} ${orgDetails[$scn,1]} $SELECTED_NETWORK_TYPE ${orgDetails[0,0]} ${ORGS_SSH[${orgDetails[$scn,0]}]}
        tmp=$scn
      done
      updateChannelConfig ${T_ORGS[$tmp]} ${T_ORGS[$og]} ${CHANNELS[0,0]} $SELECTED_NETWORK_TYPE ${ORGS_SSH[${orgDetails[$tmp,0]}]}
    fi
    AddOrgToNetwork ${T_ORGS[$og]} ${CHANNELS[0,0]} $ORDERER_TYPE "mycc" $CC_VRSN $SELECTED_NETWORK_TYPE $EXT_NTW_NAME ${orgDetails[$og,1]} $STACK_NAME ${ORGS_SSH[${orgDetails[$og,0]}]} ${orgDetails[0,0]}
  done

echo -e "${BROWN}"
echo -e "************ ${GREEN} NETWORK SETUP IS DONE ... THANK YOU FOR USING ************${NC}"
echo " "
echo " "
PrintEnd
}

function readSSHofOrgs() {
  for so_cnt in `seq 1 $1`
  do
    readSSH $so_cnt
  done
}

function readSSH() {
  echo -e "${BLUE}"
    O_cnt=$1
    read -p "   Enter SSH address of  ${orgDetails[$O_cnt,0]} organisation: " ORGS_SSH[${orgDetails[$O_cnt,0]}]    
    echo -e "${NC}"
  if [ -z "$EXT_NTW_NAME" ]; then
      echo -e "${RED}!!! Please enter a valid SSH address${NC}"
      readSSH
      return;
  fi
  checkSSH $1 ${ORGS_SSH[${orgDetails[$O_cnt,0]}]}
  echo $ORGS_SSH
}
function checkSSH() {
    status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 $2 echo ok 2>&1)

  if [[ $status == ok ]] ; then
    echo "SSH address is added"
  elif [[ $status == "Permission denied"* ]] ; then
    echo "Please place the Public key in the remote machine"
  else
    echo " SSh address is not valid , Enter again"
    readSSH $1
  fi
}
function readNetworkDeploymentType() {
  NETWORK_DEPLOY_TYPE=$(select_opt "Select the network deployment type : " "Docker-compose ( single machine )" "Docker-swarm ( single machine )" "Docker-swarm( multiple machines )")
  case "$NETWORK_DEPLOY_TYPE" in
    0) networkSelection "Docker-compose";;
    1) networkSelection "Docker-swarm-s";;
    2) networkSelection "Docker-swarm-m";;
  esac
}
function readNetworkName() {
  echo -e "${BLUE}"
    read -p "   Enter External Network name : " EXT_NTW_NAME    
    echo -e "${NC}"
  if [ -z "$EXT_NTW_NAME" ]; then
      echo -e "${RED}!!! Please enter a valid  Network Name${NC}"
      readNetworkName
      return;
  fi
  reg='^[a-zA-Z]+$'
  if [[ ! $EXT_NTW_NAME =~ $reg ]]; then
      echo -e " ${RED}!!! Network name must contain only Alphabets${NC}"
      readNetworkName
      return;
  fi
}
function readStackName() {
  echo -e "${BLUE}"
    read -p "   Enter Stack  name you need to deploy : " STACK_NAME    
    echo -e "${NC}"
  if [ -z "$STACK_NAME" ]; then
      echo -e "${RED}!!! Please enter a valid Name${NC}"
      readStackName
      return;
  fi
  reg='^[a-zA-Z]+$'
  if [[ ! $STACK_NAME =~ $reg ]]; then
      echo -e " ${RED}!!! Stack name must contain only Alphabets${NC}"
      readStackName
      return;
  fi
}
#
## N E T W O R K   S E L E C T I O N
#
function networkSelection() {
  SELECTED_NETWORK_TYPE=$1
  echo -e "${LBLUE}Network selected $1 ${NC}"
  if [ "$1" == "Docker-compose" ]; then
    readNetworkName
    echo -e "${BROWN}Generating Required network files${NC}"
  else
    readNetworkName
    readStackName
    if [ "$1" == "Docker-swarm-m" ]; then
      echo ""
      echo -e "${BROWN}Please make sure this machine is Authorized in all other Machines${NC}"
      echo -e "${RED}NOTE: ${LBLUE}Copy the below string in .ssh/authorized_keys file${NC}"
      echo -e "${GREEN}"
      cat ~/.ssh/id_rsa.pub
      echo -e "${NC}"
      O_S_cnt=$( expr ${#orgDetails[@]} / 3)
      CN_s_O=$(expr $O_S_cnt - 1)
      readSSHofOrgs $CN_s_O
    fi
    echo -e "${BROWN}Generating Required network files${NC}"
  fi
  generateDockerFiles
}

yourConfig() {
  echo -e "${BROWN}Your Network configuration ↓${NC}"
  arrOrgDetails
  arrCons
  arrChnls
  printOrderer
  askProceed "Continue To generate certificates and network (y/n) ? "
  gCryptoConfig
  gConfigFile
  askProceed "Continue To generate Docker network files (y/n) ? "
  readNetworkDeploymentType
}
getOrdererDetails() {
  ORDERER_TYPE="$1"
  if [ "$ORDERER_TYPE" == "SOLO" ]; then
    NO_OF_ORDERERS=1
    readOrdererProfileName
    readOrdererConsortium "${CON[@]}"
    #printOrderer
  else
    readOrdererProfileName
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
  #sleep 5
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

function select_opt {
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



