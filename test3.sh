#!/bin/bash

. ./test.sh

main
sleep 2
PPO=3
main
sleep 3
main
echo $TR
echo  $PPO > tmp.txt