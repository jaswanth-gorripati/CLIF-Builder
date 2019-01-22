#!/bin/bash
BROWN='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
GREEN='\033[0;32m'
function PrintEnd() {
echo -e "${LBLUE}"
echo "   _     _       __       __     _    ______           "
echo "  | |   | |     /  \     |  \   | |  |  _   |          "
echo "  | |___| |    / __ \    |   \  | |  | |_|  |          "
echo "  |  ___  |   /  __  \   | |\ \ | |  |  _  /            "
echo "  | |   | |  /  /  \  \  | | \ \| |  | |_| \            "
echo "  |_|   |_| /__/    \__\ |_|  \___|  |______|            "
echo 
echo ""
echo -e "${NC}"
}