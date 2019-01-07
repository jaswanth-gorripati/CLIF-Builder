#!/bin/bash

# file1=$(cat file1.yaml)
# file2=$(cat file2.yaml)
# cat << EOF >> temp.yaml
# ${file1}
# ${file2}
# EOF

D_ZOO_COUNT=4
for zoo_cnt in `seq 0 ${D_ZOO_COUNT}`
do
    ZOO_STRING="${ZOO_STRING}server.$(expr $zoo_cnt + 1)=zookeeper${zoo_cnt}:2888:3888 "
    KF_ZOO_STR="${KF_ZOO_STR}zookeeper${zoo_cnt}:2181,"
done
ZOO_STRING=${ZOO_STRING::-1}
KF_ZOO_STR=${KF_ZOO_STR::-1}
echo $ZOO_STRING
echo $KF_ZOO_STR
function add() {
    echo $1
}
add "${ZOO_STRING}"