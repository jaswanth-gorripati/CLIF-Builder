# CLIF  

*CLIF is a cli based fabric network builder*

> Note :
    > To deploy network between Multiple machines *SSH* is used , So make sure that remote machines has ssh installed and has *_id_rsa.pub_*  key of Main machine ( which can be found in .ssh folder ) in their *_authorized_keys_* file in *.ssh* folder

## CLIF facilites you to choose 

+ Number of Organisations 
+ Number of Channels
+ Type of Ordering service _( Solo / Kafka)_
+ Network deployment type
    + In single system using _Docker-compose_ or _Docker-swarm_
    + In multiple systems using _Docker-swarm_
+ Chaincode type
    + NodeJs chaincode
    + Java chaincode
    + Golang chaincode
    + Composer chaincode

