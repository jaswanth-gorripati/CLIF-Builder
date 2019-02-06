#!/bin/bash

echo "******************************** Installing  Prerequirements *****************************"
node -v
npm -v
docker -v
docker images|grep hyperledger
echo ""
echo ""
echo "******************************** Prerequirements installed *****************************"