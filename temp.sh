#!/usr/bin/env bash

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {
  
  # little helpers for terminal print control and key input
  LBLUE='\033[1;34m'
  BLUE='\033[0;34m'
  NC='\033[0m'
  ESC=$(printf "\033")
  cursor_blink_on()  { printf "%s" "${ESC}[?25h"; }
  cursor_blink_off() { printf "%s" "${ESC}[?25l"; }
  cursor_to()        { printf "%s" "${ESC}[$1;${2:-1}H"; }
  print_option()     { printf "${BLUE}%s${NC}" "   $1 "; }
  print_selected()   { printf "${BLUE}> %s${NC}""${ESC}[1;34m $1 ${ESC}[0m"; }
  get_cursor_row()   { IFS=';' read -rsdR -p $'\E[6n' ROW COL; echo "${ROW#*[}"; echo "$COL" > /dev/null; }
  key_input()        {
    read -rs -n3 key 2>/dev/null >&2
    if [[ $key = ${ESC}[A ]]; then echo "up"; fi
    if [[ $key = ${ESC}[B ]]; then echo "down"; fi
    if [[ $key = "" ]]; then echo "enter"; fi
  }

  # initially print empty new lines (scroll down if at bottom of screen)
  # for opt; do printf "\n"; done

  # determine current screen position for overwriting the options
  # local lastrow=`get_cursor_row`
  # local startrow=$(($lastrow - $#))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  #trap "cursor_blink_on; stty echo 2> /dev/null; clear; exit" 2
  cursor_blink_off

  local selected=1
  local title="$1"
  shift

  while true; do
    clear
    printf "%s" "$title"
    # print options by overwriting the last lines
    local idx=1
    for opt; do
      cursor_to $((idx + 1))
      if [ $idx -eq $selected ]; then
        print_selected "$opt"
      else
        print_option "$opt"
      fi
      ((idx++))
    done

    # user key control
    case $(key_input) in
      enter) break;;
      up)    ((selected--));
        if [ $selected -lt 1 ]; then selected=$(($#)); fi
      ;;
      down)  ((selected++));
        if [ $selected -gt $# ]; then selected=1; fi
      ;;
    esac
  done

  # cursor position back to normal
  printf "\n"
  cursor_blink_on

  return $((selected - 1))
}
function installingPre {
  echo "installing Pre-requirements"
}
function installPre {
  insP=$(select_opt "Do you want to install all Prerequirements ?" "YES" "NO" )
  case "$insP" in 
    0) installingPre ;;
    1) echo "Assuming Prerequirements  are installed";;
  esac
}
function networkSelected {
  echo "$1"
  installPre
}

function orderertype {
 select_option "$@" 1>&2
  local result=$?
  #echo $result  
}

function dbselection {
  select_option "$@" 1>&2
  local result=$?
  echo $result
}

function select_opt {
  select_option "$@" 1>&2
  local result=$?
  echo $result
}

function versions {
  select_option "$@" 1>&2
  local result=$?
  echo $result
}

userChoice=$(select_opt "Select the Hyperledger-fabric version to work on :" "v1.1" "v1.2" "v1.3" "v1.4" )
# clear
case "$userChoice" in
  0) networkSelected "v1.1";;
  1) networkSelected "v1.2";;
  2) networkSelected "v1.3";;
  3) networkSelected "v1.4";;
esac


case "$ordererlist" in 
  0) echo "selected kafka";;
  1) echo "selected solo";; 
esac


case "$dblist" in 
  0) echo "selected couchdb";;
  1) echo "selected leveldb";; 
esac



case "$versionlist" in 
  0) echo "selected 1.1";;
  1) echo "selected 1.2";;
  2) echo "selected 1.3";;
  3) echo "selected 1.4";; 
esac