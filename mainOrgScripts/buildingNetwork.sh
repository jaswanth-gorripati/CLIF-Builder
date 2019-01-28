#!/bin/bash
BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
echo $@
CHANNEL_NAME="$1"
DOMAIN="$2"
CC_SRC_PATH="$3"
CC_VERSION="$4"
ORDR_ADRS=orderer0
P_CNT=$5
IS_INSTANT=$6
POL="${7}"
DELAY="3"
TIMEOUT="10"
LANGUAGE="golang"
COUNTER=1
MAX_RETRY=5
INS_RETRY=3
CCR=1
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/${ORDR_ADRS}.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo -e "${GREEN}"
echo "Building Initial channel and adding An Organisation"
echo -e "${NC}"

setGlobals () {
	PEER=$1
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${DOMAIN}.example.com/peers/peer0.${DOMAIN}.example.com/tls/ca.crt
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${DOMAIN}.example.com/users/Admin@${DOMAIN}.example.com/msp
    CORE_PEER_ADDRESS=peer${PEER}.$DOMAIN.example.com:7051
}

# verify the results
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo -e "${RED}!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
        echo "========= ERROR !!! FAILED to execute ==========="
		echo -e "${NC}"
   		exit 1
	fi
}
verifyChannelCreation () {
    if [ $1 -ne 0 -a $CCR -lt 2 ] ; then
        echo -e "${BROWN}"
        echo " **************** NOTE :"
        echo -e "${LBLUE} It Seems Orderer is taking much longer to connect ...Go Grab Some Coffee , the process will restart in --- 5 MINUTES ${NC}"
        sleep 250
        CCR=` expr $CCR + 2`
        COUNTER=1
        createChannelWithRetry
        elif [ $CCR -eq 2 ]; then
            echo "Channel Creation failed ....."
            exit 1        
    fi
}
joinChannelWithRetry () {
    setGlobals $1
    set -x
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
    set +x
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.${DOMAIN}.exapmle.com failed to join the channel, Retry after $DELAY seconds"
		sleep $DELAY
		joinChannelWithRetry $peer 
        return
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${peer}.${DOMAIN}.exapmle.com has failed to Join the Channel"
}
createChannelWithRetry () {
    setGlobals 0
    set -x
    peer channel create -o $ORDR_ADRS.example.com:7050 -c $CHANNEL_NAME -f ./$CHANNEL_NAME.tx --tls --cafile $ORDERER_CA >log.tx
    res=$?
    set -x
    cat log.tx
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.${DOMAIN}.exapmle.com failed to create channel, Retry after $DELAY seconds"
		sleep $DELAY
		createChannelWithRetry 0 
        return
	else
		COUNTER=1
	fi
    verifyChannelCreation $res 
    echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
    echo
}
updateAnchorWithRetry () {
    setGlobals $1
    set -x
    peer channel update -o $ORDR_ADRS.example.com:7050 -c $CHANNEL_NAME -f ./${DOMAIN}MSPanchors.tx --tls --cafile $ORDERER_CA >log.tx
    res=$?
    set -x
    cat log.tx
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${peer}.${DOMAIN}.exapmle.com failed to update anchor Peer, Retry after $DELAY seconds"
		sleep $DELAY
		updateAnchorWithRetry $peer 
        return
	else
		COUNTER=1
	fi
    verifyResult $res "peer${peer}.${DOMAIN}.exapmle.com failed to update anchor Peer"
    echo "===================== peer${peer}.${DOMAIN}.exapmle.com updated anchor Peer successfully ===================== "
    echo
}

installChaincodeWithRetry () {
    setGlobals $1 
    set -x
	peer chaincode install -n mycc -v ${CC_VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} >&log.txt
	res=$?
    set +x
	cat log.txt
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "Chaincode installation on peer${peer}.${DOMAIN}.exapmle.com has Failed, Retry after $DELAY seconds"
		sleep $DELAY
		installChaincodeWithRetry $peer 
        return
	else
		COUNTER=1
	fi
	verifyResult $res "Chaincode installation on peer${peer}.${DOMAIN}.exapmle.com has Failed"
	echo "===================== Chaincode is installed on peer${peer}.${DOMAIN}.exapmle.com ===================== "
	echo
}
instantiatedWithRetry () {
    setGlobals $1 
    set -x
    peer chaincode instantiate -o $ORDR_ADRS.example.com:7050 --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v ${CC_VERSION} -c '{"Args":["init","a", "100", "b","200"]}' -P "OR ${POL}"
    res=$?
    set +x
    cat log.txt
    if [ $res -ne 0 -a $COUNTER -lt $INS_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "Chaincode instantiation on peer0.${DOMAIN}.exapmle.com on channel '$CHANNEL_NAME' failed, Retry after $DELAY seconds"
		sleep $DELAY
		instantiatedWithRetry $1
        return
	else
		COUNTER=1
	fi
    verifyResult $res "Chaincode instantiation on peer0.${DOMAIN}.exapmle.com on channel '$CHANNEL_NAME' failed"
    echo "===================== Chaincode Instantiation on peer0.${DOMAIN}.exapmle.com on channel '$CHANNEL_NAME' is successful ===================== "
    echo
}
chainQuery () {
    sleep 10
    set -x
    peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
    res=$?
    set +x
    cat log.txt
    EXPECTED_RESULT=100
    if [ $res -ne 0 -a $COUNTER -lt $INS_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo -e "${RED}Chaincode query on channel '$CHANNEL_NAME' failed, Retry after $DELAY seconds${NC}"
		sleep $DELAY
		chainQuery
        return
    else
        COUNTER=1
    fi
    if [ $res -eq 0 ]; then
        VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
        if [ "$VALUE" == "$EXPECTED_RESULT" ]; then
            echo -e "${GREEN}"
            echo "======= Expected value  -  Returned Value =========="
            echo "======= ${EXPECTED_RESULT}             -  ${VALUE}            =========="
            echo
            echo -e "======= SUCCESFULLY INSTANTIATED CHAINCODE ON  CHANNEL ${CHANNEL_NAME} ==========${NC}"
            exit 0
        else
            echo -e "${RED}Expected ${EXPECTED_RESULT} but got ${VALUE}"
            echo "!!!!!!!!!!... FAILED...!!!!!!!!!!${NC}"
            exit 1
        fi
    fi
}

echo "IS_INSTANT= ${IS_INSTANT}"
if [ $IS_INSTANT == true ]; then
    #Instantiation 
    echo -e "${GREEN}"
    echo "========== Instantiation on ${CHANNEL_NAME} STARTED ========="
    echo -e "${NC}"
    sleep 5
    instantiatedWithRetry 0
    sleep 20
    #
    # Query 
    echo -e "${GREEN}"
    echo "========== Attempting to Query peer0.${DOMAIN}.exapmle.com ...$(($(date +%s)-starttime)) secs =========="
    echo -e "${NC}"
    chainQuery
else
# Channel creation 
echo -e "${GREEN}"
echo "========== Channel ${CHANNEL_NAME} creation started =========="
echo -e "${NC}"
#sleep 5
sleep 10
createChannelWithRetry
#sleep 10
#
# Join Channel
echo -e "${GREEN}"
echo "========== Peers  Joining channel started =========="
echo -e "${NC}"
peer=0
while [ "$peer" != "$P_CNT" ]
do
    #sleep 30
    joinChannelWithRetry $peer 
    echo "===================== peer${peer}.${DOMAIN}.exapmle.com joined on the channel \"$CHANNEL_NAME\" ===================== "
    sleep $DELAY
    echo
    peer=$(expr $peer + 1)
done
##sleep 10
#
# Update Anchor peer 
echo -e "${GREEN}"
echo "========== Updating Anchor peer ========="
echo -e "${NC}"
#sleep 10
updateAnchorWithRetry 0
#
# Chaincode installation
echo -e "${GREEN}"
echo "========== Chaincode installation started ========== "
echo -e "${NC}"
#for peer `seq 0 ${P_CNT}`
peer=0
while [ "$peer" != "$P_CNT" ]
do
    #sleep 10
    installChaincodeWithRetry $peer 
    sleep $DELAY
    echo
    peer=$(expr $peer + 1)
done
fi