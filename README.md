<p align="center"><img src="https://github.com/jaswanth-gorripati/CLIF-Builder/blob/master/logo/logo.png" alt="CLIF" width="250" height="250" /></p>

_CLIF_ is a cli ( terminal ) based fabric network builder

## CLIF allows you to choose

- Network deployment type
  - In single system using Docker-compose or Docker-swarm
  - Across multiple systems using Docker-swarm
- Organisation details
  - Number of peers
  - Storage type ( couchdb / Leveldb )
- Number of Channels ( multiple channels support is in development )
- Type of Ordering service ( Solo / Kafka / RAFT )
  - Number of Zookeepers
  - Number of Kafkas
  - Number of Orderers
- Chaincode type
  - Golang chaincode

## Running the application

- To run the application Git clone the specific repository and checkout the required fabric version branch, Example :
- For fabric version v1.1
- git checkout clif-v1.1
- Go to the CLIF-Builder folder and run ./CLIF.sh
- Enter the details as it prompts

> Note : To deploy network between Multiple machines SSH is used , So make sure that remote machines has SSH installed and has id_rsa.pub key of Main machine ( which can be found in. ssh folder ) in their authorized_keys file in .ssh folder
