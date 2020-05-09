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
echo $@
ORDR_ADRS=orderer0
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
		echo "peer${1}.${DOMAIN}.example.com failed to join the channel, Retry after $DELAY seconds"
		sleep 3
		joinChannelWithRetry $1
        return
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${1}.${DOMAIN}.example.com has failed to Join the Channel"
}
installChaincode () {
	setGlobals $1
        set -x
	#go get github.com/hyperledger/fabric-chaincode-go/shim
	peer lifecycle chaincode install ${CHAINCODENAME}.tar.gz >&log.txt
	res=$?
        set +x
	cat log.txt
    if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer$1.${DOMAIN}.example.com failed to Install chaincode , Retry after $DELAY seconds"
		sleep 3
		installChaincode $1
        return
	else
		COUNTER=1
	fi
	verifyResult $res "Chaincode installation on peer$1.${DOMAIN}.exapmle.com has Failed"
	echo "===================== Chaincode is installed on peer$1.${DOMAIN}.example.com ===================== "
	echo
}
approveFromOrgWithRetry () {
    setGlobals $1
    set -x
    peer lifecycle chaincode queryinstalled >&pkg.txt
    PACKAGE_ID=$(sed -n "/${CHAINCODENAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" pkg.txt)
    echo "package ID : ${PACKAGE_ID}"
	peer lifecycle chaincode approveformyorg -o ${ORDR_ADRS}.example.com:7050 --ordererTLSHostnameOverride ${ORDR_ADRS}.example.com --tls true --cafile $ORDERER_CA --channelID ${CHANNEL_NAME} --name ${CHAINCODENAME} --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence 1
	res=$?
    set +x
     if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "Approving Chaincode Packagefrom ${DOMAIN} has Failed, Retry after $DELAY seconds"
		sleep $DELAY
		approveFromOrgWithRetry 1 
        return
	else
		COUNTER=1
	fi
	verifyResult $res "Approving Chaincode Package from ${DOMAIN} has Failed"
	echo "===================== Chaincode Package is Approved form ${DOMAIN} organisation===================== "
	echo
}
	
if [ "$IS_INSTALL" == "true" ]; then
	peersToJoin=0
	echo "${peersToJoin}"
	echo $P_CNT
	while [ "$peersToJoin" != "$P_CNT" ]
	do
		#sleep 10
		installChaincode $peersToJoin 
		sleep $DELAY
		peersToJoin=$(expr $peersToJoin + 1)
		echo $peersToJoin
	done
elif [ "$IS_INSTALL" == "approve" ]; then
	approveFromOrgWithRetry 0
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