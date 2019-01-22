#!/bin/bash

DTNPATH="./network.yaml"
function addNetwork() {
    EXTERNAL_NETWORK=$1
    n_type=$2
    cat << EOF > ${DTNPATH}
networks:
EOF
if [ "$n_type" != "Docker-compose" ]; then
cat << EOF >> ${DTNPATH}
  ${EXTERNAL_NETWORK}:
    external:
      name: ${EXTERNAL_NETWORK}
EOF
else
cat << EOF >> ${DTNPATH}
  ${EXTERNAL_NETWORK}:
EOF
fi
}
#addNetwork ext