#!/bin/bash

. ./test1.sh

function main(){
    SDE=${PPO}000
    echo $SDE
    PPO=$((PPO + 1))
}