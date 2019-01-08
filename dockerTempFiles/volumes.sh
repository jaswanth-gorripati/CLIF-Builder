#!/bin/bash

DTVPATH="./volume.yaml"

function addVersion() {
    if [ "$1" == "Docker-compose" ]; then
        cat << EOF > ${DTVPATH}
version: '2'
EOF
    else
     cat << EOF > ${DTVPATH}
version: '3'
EOF
fi
}

function addVolumes() {
    cat << EOF >> ${DTVPATH}
volumes:
EOF

}



#peer${cnt}.${D_O_NAME}.example.com:
function addPeerVolumes() {
    D_O_NAME=$2
    for cnt in `seq 0 $(expr $1 - 1)`
do
    cat << EOF >> ${DTVPATH}
  peer${cnt}.${D_O_NAME}.example.com:
EOF
done
}
#couchdb${cnt}.${D_O_NAME}:
function addCouchVolumes() {
    D_O_NAME=$2
    for cnt in `seq 0 $(expr $1 - 1)`
    do
   cat << EOF >> ${DTVPATH}
  couchdb${cnt}.${D_O_NAME}:
EOF
done
}
function addOrdererVolumes() {
    for cnt in `seq 0 $(expr $1 - 1)`
    do
       cat << EOF >> ${DTVPATH}
  orderer${cnt}.example.com:
EOF
done
}
function addKafkaVolumes() {
    for cnt in `seq 0 $1`
    do
       cat << EOF >> ${DTVPATH}
  kafka${cnt}:
EOF
done
}
function addZookeeperVolumes() {
    for cnt in `seq 0 $1`
    do
       cat << EOF >> ${DTVPATH}
  zookeeper${cnt}.data:
  zookeeper${cnt}.datalog:
EOF
done
}
# addVersion "docker-swarm"
# addVolumes
# addCouchVolumes 2 org1
# addKafkaVolumes 3 
# addOrdererVolumes 3
# addPeerVolumes org1 3
# addZookeeperVolumes 3