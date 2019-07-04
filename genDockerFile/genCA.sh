#!/bin/bash

#. ./details.sh
. ./env.sh

function writeCA() {

    if [ "$DOCKER_NETWORK_TYPE" != "DOCKER-COMPOSE" ]; then
        echo "  rca_${ORG}:"
        echo "    image: hyperledger/fabric-ca:${FABRIC_CA_TAG}"
        echo "    deploy:"
        echo "      replicas: 1"
        echo "      restart_policy:"
        echo "      condition: on-failure"
        echo "    hostname: rca-${ORG}"
    else
        echo "  rca.${ORG}:"
        echo "    image: hyperledger/fabric-ca:${FABRIC_CA_TAG}"
        echo "    container_name: rca-${ORG}"
    fi
    echo "    command: /bin/bash -c '/scripts/start-intermediate-ca.sh $ORG 2>&1 | tee /$INT_CA_LOGFILE'"
    echo "    environment:
      - FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_CSR_CN=rca-${ORG}
      - FABRIC_CA_SERVER_CSR_HOSTS=rca-${ORG}
      - FABRIC_CA_SERVER_DEBUG=true
      - BOOTSTRAP_USER_PASS=$ROOT_CA_ADMIN_USER_PASS
      - TARGET_CERTFILE=$ROOT_CA_CERTFILE
      - FABRIC_ORGS="$ORGS"
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
      - rca.${ORG}.${DOMAIN}:/etc/hyperledger/fabric-ca
    ports:
      - "${RCA_PORT}054:7054"
    networks:
      ${EXTERNAL_NETWROK_NAME}:
        aliases:
          - rca-${ORG}
"
if [ "$USE_ICA" == "true" ]; then
    initOrgVars
    if [ "$DOCKER_NETWORK_TYPE" != "DOCKER-COMPOSE" ]; then
        echo "  ica_${ORG}:"
        echo "    image: hyperledger/fabric-ca:${FABRIC_CA_TAG}"
        echo "    deploy:"
        echo "      replicas: 1"
        echo "      restart_policy:"
        echo "      condition: on-failure"
        echo "    hostname: ica-${ORG}"
    else
        echo "  ica.${ORG}:"
        echo "    image: hyperledger/fabric-ca:${FABRIC_CA_TAG}"
        echo "    container_name: ica-${ORG}"
    fi
    echo "    command: /bin/bash -c '/scripts/start-intermediate-ca.sh $ORG 2>&1 | tee /$INT_CA_LOGFILE'"
    echo "    environment:
      - FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca
      - FABRIC_CA_SERVER_CA_NAME=$INT_CA_NAME
      - FABRIC_CA_SERVER_INTERMEDIATE_TLS_CERTFILES=$ROOT_CA_CERTFILE
      - FABRIC_CA_SERVER_CSR_HOSTS=$INT_CA_HOST
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_DEBUG=true
      - BOOTSTRAP_USER_PASS=$INT_CA_ADMIN_USER_PASS
      - PARENT_URL=https://$ROOT_CA_ADMIN_USER_PASS@$ROOT_CA_HOST:7054
      - TARGET_CHAINFILE=$INT_CA_CHAINFILE
      - ORG=$ORG
      - FABRIC_ORGS=$ORG
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
      - ica.${ORG}.${DOMAIN}:/etc/hyperledger/fabric-ca
    ports:
      - "${ICA_PORT}054:7054"
    networks:
      ${EXTERNAL_NETWROK_NAME}:
        aliases:
          - rca-${ORG}
"
fi
RCA_PORT=$((RCA_PORT + 2))
ICA_PORT=$((ICA_PORT + 2))
}