#!/bin/bash

DTNPATH="./network.yaml"
function addNetwork() {
    EXTERNAL_NETWORK=$1
    cat << EOF > ${DTNPATH}
networks:
  ${EXTERNAL_NETWORK}:
    external:
      name: ${EXTERNAL_NETWORK}
EOF
}
#addNetwork ext