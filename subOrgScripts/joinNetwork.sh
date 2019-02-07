#!/bin/bash

DOMAIN="$1"
CHANNEL_NAME="$2"
ORDERER_NAME=$3
CHAINCODENAME="$6"
VERSION=$7
IS_INSTALL=$5
LANGUAGE=$9
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/$ORDERER_NAME.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
echo "$DOMAIN"
#CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
CC_SRC_PATH="$8"
P_CNT=$4
echo $VERSION
DELAY=5
# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED ==========="
		echo
   		exit 1
	fi
}
setGlobals () {
	PEER=$1
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${DOMAIN}.example.com/peers/peer0.${DOMAIN}.example.com/tls/ca.crt
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${DOMAIN}.example.com/users/Admin@${DOMAIN}.example.com/msp
    CORE_PEER_ADDRESS=peer${PEER}.$DOMAIN.example.com:7051
}
## Sometimes Join takes time hence RETRY at least for 5 times
joinChannelWithRetry () {
    setGlobals $1
        set -x
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
        set +x
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer0.${DOMAIN}.example.com failed to join the channel, Retry after $DELAY seconds"
		sleep 3
		joinChannelWithRetry 
        return
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer0.${DOMAIN}.example.com has failed to Join the Channel"
}
installChaincode () {
	setGlobals $1
        set -x
	peer chaincode install -n $CHAINCODENAME -v ${VERSION}  -l $LANGUAGE -p ${CC_SRC_PATH} >&log.txt
	res=$?
        set +x
	cat log.txt
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer0.${DOMAIN} failed to join the channel, Retry after $DELAY seconds"
		sleep 3
		installChaincode 
        return
	else
		COUNTER=1
	fi
	verifyResult $res "Chaincode installation on peer0.${DOMAIN}.exapmle.com has Failed"
	echo "===================== Chaincode is installed on peer0.${DOMAIN}.example.com ===================== "
	echo
}
if [ $IS_INSTALL == true ]; then
peer=0
while [ "$peer" != "$P_CNT" ]
do
    #sleep 10
    installChaincode $peer 
    sleep $DELAY
    echo
    peer=$(expr $peer + 1)
done
else
set -x
peer channel fetch 0 ${CHANNEL_NAME}.block -o $ORDERER_NAME.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
set +x
res=$?
verifyResult $res "Failed to fetch channel block"
peer=0
echo $P_CNT
while [ "$peer" != "$P_CNT" ]
do
    #sleep 10
    joinChannelWithRetry $peer 
    sleep $DELAY
    echo
    peer=$(expr $peer + 1)
done
sleep 1
fi
exit 0