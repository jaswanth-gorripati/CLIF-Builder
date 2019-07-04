#!/bin/bash

export FABRIC_CA_TAG=${FABRIC_TAG:-1.4.0}
export MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
CA_BINARY_FILE=hyperledger-fabric-ca-${MARCH}-${FABRIC_CA_TAG}.tar.gz
URL=https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca/${MARCH}-${FABRIC_CA_TAG}/${CA_BINARY_FILE}

SDIR=$(dirname "$0")

. ./details.sh
. ./genVolumes.sh

rm -rf $ORG_PATH
mkdir -p $ORG_PATH
mkdir -p $ORG_PATH/data/

function create() {
    createDockerFiles
    {
        addVolumes
        echo "services:"
    } > $ORG_PATH/docker-compose.yaml
}

function createDockerFiles() {
    createDockerFile orderer
    createDockerFile peer
    createDockerFile tools
}

# createDockerFile
function createDockerFile {
   {
      echo "FROM hyperledger/fabric-${1}:${FABRIC_TAG}"
      echo 'RUN apt-get update && apt-get install -y netcat jq && apt-get install -y curl && rm -rf /var/cache/apt'
      echo "RUN curl -o /tmp/fabric-ca-client.tar.gz $URL && tar -xzvf /tmp/fabric-ca-client.tar.gz -C /tmp && cp /tmp/bin/fabric-ca-client /usr/local/bin"
      echo 'RUN chmod +x /usr/local/bin/fabric-ca-client'
      echo 'ARG FABRIC_CA_DYNAMIC_LINK=false'
      # libraries needed when image is built dynamically
      echo 'RUN if [ "\$FABRIC_CA_DYNAMIC_LINK" = "true" ]; then apt-get install -y libltdl-dev; fi'
   } > $ORG_PATH/fabric-ca-${1}.dockerfile
}



