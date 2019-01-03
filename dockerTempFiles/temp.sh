#!/bin/bash

# file1=$(cat file1.yaml)
# file2=$(cat file2.yaml)
# cat << EOF >> temp.yaml
# ${file1}
# ${file2}
# EOF

zf="zk1:2456,zk2:8765,"
zf=${zf::-1}
echo $zf
dt=2
echo ${dt}000