#!/bin/bash

##############################################################
# Script: backup.sh                                          
# Author: Andy Feys (andy@feys.be)                           
# Date:   Thursday June 4th 2020                             
##############################################################

readonly SCRIPTNAME=`basename "$0"`
readonly VERSION='0.5'
readonly AUTHOR="Andy Feys"

##############################################################
# Initializing some variables                                
##############################################################

# initializing some color variables, useful for outputting text
# more info can be found at https://en.wikipedia.org/wiki/ANSI_escape_code
BLACK='\033[0;30m'
RED='\033[0;31m'
BRIGHTRED='\033[1;31m'
GREEN='\033[0;32m'
BRIGHTGREEN='\033[1;32m'
YELLOW='\033[0;33m'
BRIGHTYELLOW='\033[1;33m'
BLUE='\033[0;34m'
BRIGHTBLUE='\033[1;34m'
MAGENTA='\033[0;35m'
BRIGHTMAGENTA='\033[1;35m'
CYAN='\033[0;36m'
BRIGHTCYAN='\033[1;36m'
WHITE='\033[0;37m'
BRIGHTWHITE='\033[1;37m'
RESET='\033[0;0m'

# Some variables to store command line parameters
clp_show_help=false
clp_interactive_mode=false
clp_restore=""
clp_config_file_name=""
clp_write_config_file=""           # store the current config in a file with this name
clp_directory_to_backup=""
clp_directory_to_store_backup=$( getent passwd "$USER" | cut -d: -f6 )  # store the backupfile by default in the users' home directory
clp_encryption_password=""
clp_comment=""

##############################################################
# functions                                                  
##############################################################

function array_contains() {
  local n=$#
  local value=${!n}
  for ((i=1;i < $#;i++)) {
    if [ "${!i}" == "${value}" ]; then
      echo "y"
      return 0
    fi
  }	
  echo "n"
  return 1
}

function clean_comment() {
  a=${1//[^[:alpha:]]/_}
  a=${a//__/_}
  echo "${a,,}"
}

#unused
#function isvarset(){
#	 local v="$1"
#	 [[ ! ${!v} && ${!v-unset} ]] && echo "Variable not found." || echo "Variable found."
#}

function show_welcome() {
  echo -e "${GREEN}+-----------------------------------------------------------------------+${RESET}"
  echo -e "${GREEN}|${RESET} ${BRIGHTBLUE}$SCRIPTNAME${RESET} $VERSION                                                         ${GREEN}|${RESET}" 
  echo -e "${GREEN}|${RESET} by ${GREEN}$AUTHOR${RESET}                                                          ${GREEN}|${RESET}" 
  echo -e "${GREEN}+-----------------------------------------------------------------------+${RESET}"
}

function show_intro() {
  show_welcome
  echo -e "$SCRIPTNAME -h or $SCRIPTNAME --help to show all options"
  echo -e " "
}

function show_help() {
  show_welcome
  echo -e "${GREEN}|${RESET}                                                                       ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} ${BRIGHTGREEN}Usage${RESET}: $SCRIPTNAME [OPTION]...                                          ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} Backups a folder to a tar.gz (or tar.gz.gpg) file.                    ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET}                                                                       ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} If no options are provided, then the program is started in            ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} interactive mode.                                                     ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET}                                                                       ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} ${BRIGHTGREEN}Command line options${RESET}:                                                 ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -h, --help                        show help                           ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -b, --backup <backupfolder>       backup this folder                  ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -t, --targetdir <targetdir>       store the backup in this folder     ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -o, --comment <comment>           add a short comment to backup       ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET}                                   filename                            ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -p, --password <password>         encryption password                 ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -i, --interactive                 start the program interactively     ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET}                                   (all other parameters are ignored)  ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -c, --config <configfile>         load settings from configfile       ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -w, --writeconfig <configfile>    write settings to configfile        ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET} -r, --restore <backupfile>        restore a backup to targetdir       ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET}                                   using password                      ${GREEN}|${RESET}"
  echo -e "${GREEN}|${RESET}                                                                       ${GREEN}|${RESET}"
  echo -e "${GREEN}+-----------------------------------------------------------------------+${RESET}"
  echo -e " "
}

##############################################################
# get all command line parameters (if any)                   
##############################################################

clp_interactive_mode=true  # start in interactive mode by default

while [[ "$#" -gt 0 ]]
do
  case $1 in
    -h|--help)
      echo "will show help"
      clp_interactive_mode=false
      clp_show_help=true
      ;; 
    -c|--config)
      echo "will use configfile $2"
      clp_interactive_mode=false
      clp_config_file_name=$2
      ;;
    -b|--backup)
      echo "will backup $2"
      clp_interactive_mode=false
      clp_directory_to_backup=$2
      ;;
    -r|--restore)
      echo "will restore $2"
      clp_interactive_mode=false
      clp_restore=$2
      ;;
    -w|--writeconfig)
      echo "will write configfile $2"
      clp_interactive_mode=false
      clp_write_config_file=$2
      ;;
    -t|--targetdir)
      echo "will write backup to $2"
      clp_interactive_mode=false
      clp_directory_to_store_backup=$2
      ;;
    -p|--password)
      echo "will use password $2"
      clp_interactive_mode=false
      clp_encryption_password=$2
      ;;
    -i|--interactive)
      echo "will launch interactive "
      clp_interactive_mode=true
      ;;			
  esac	
  shift
done


##############################################################
# show welcome message                                       
##############################################################
if [ ${clp_show_help} == true ]
then
  show_help
  exit
else
  show_intro
fi


if [ ${clp_interactive_mode} == true ]
then

##############################################################
# INTERACTIVE MODE
##############################################################


  # select which folder to backup                              
  ##############################################################

  directory2backup=$(pwd)
  targetdirectory="/home/afeys"
  while true;
  do
    dirs=("[backup current directory]")
    dirs+=("[..]")
    dirs+=(*/)
    dirs+=("Quit")
    nrdirs=${#dirs[@]} 
    currentdir=$(pwd)
    let realnrdirs=${#dirs[@]}-3;
    echo -e "${BRIGHTWHITE}Current folder is ${RESET}${BRIGHTBLUE}$currentdir${RESET}"
    echo -e "${WHITE}There are $realnrdirs subfolders in the current folder${RESET}"
    echo -e " "
    echo -e "${GREEN}Folders available in this folder:${RESET}"
    PS3="Please select folder to backup:"
    select d in "${dirs[@]}"; do 
      if [ $(array_contains "${dirs[@]}" "$d") == "y" ];
      then
        case $d in
          "[backup current directory]")
            directory2backup=$(pwd)
            break
            ;;
          "[..]")
            cd .. 
            ;;
          "Quit")
            echo -e "Script exited. ${GREEN}See you next time.${RESET}"
            exit
            ;;
          *)
            cd "$d" && pwd
            ;;
        esac
        break
      else
        echo "Wrong selection: Select any number from 1-$nrdirs"
      fi
    done
    unset dirs
    unset nrdirs
    if [ "$d" = "[backup current directory]" ];
    then
      break
    fi
  done

  # enter some comment or info about this backup               
  ##############################################################

  echo -e "${GREEN}Please enter some comment about this backup (50char max), this will be appended to the filename:${RESET}"
  read backupcomment

  cleanedcomment=$(clean_comment "$backupcomment")
  cleanedcomment=${cleanedcomment:0:50}

  #echo -e "${RED}$cleanedcomment${RESET}"

  # do you want to encrypt this backup? Then enter a password. 
  ##############################################################

  echo -e "${GREEN}If you want to encrypt this backup, please enter a password:${RESET}"
  read -s backuppassword

  #echo -e "password entered is ${RED}$backuppassword${RESET}"

else # else of  "if [ ${clp_interactive_mode} == true }" statement

##############################################################
# NON-INTERACTIVE MODE
##############################################################
  if [ "${clp_config_file_name}" != "" ];
  then
  # load variables from config file
    while IFS='= ' read -r key value; do
      case $key in 
        "directory_to_backup")
          directory2backup=${value}
          ;;
        "targetdirectory")
          targetdirectory=${value}
          ;;
        "comment")
          cleanedcomment=${value}
          ;;
        "password")
          backuppassword=${value}
          ;;
      esac        
    done < $clp_config_file_name
  fi

  # load variables from command line parameters
  if [ "${clp_directory_to_backup}" != "" ];
  then
    directory2backup=${clp_directory_to_backup}
  fi
  if [ "${clp_directory_to_store_backup}" != "" ];
  then
    targetdirectory=${clp_directory_to_store_backup}
  fi
  if [ "${clp_encryption_password}" != "" ];
  then
    backuppassword=${clp_encryption_password}
  fi
  if [ "${clp_comment}" != "" ];
  then
   cleanedcomment=${clp_comment}
  fi

  # write variables to config file if needed
  if [ "${clp_write_config_file}" != "" ];
  then
    # write config to config file
    echo "directory_to_backup = ${directory2backup}" > ${clp_write_config_file}
    echo "targetdirectory = ${targetdirectory}" >> ${clp_write_config_file}
    echo "comment = ${cleanedcomment}" >> ${clp_write_config_file}
    echo "password = ${backuppassword}" >> ${clp_write_config_file}
  fi

fi # end of "if [ ${clp_interactive_mode} == true }" statement


##############################################################
# do the backup                                              
##############################################################

if [[ -z ${clp_restore} ]]
then
  # do a backup
  if [[ -z "$backuppassword" ]];
  then
    echo -e "Starting backup of ${GREEN}$directory2backup${RESET}. "
    cd $targetdirectory
    tar cvpfz "$(directory2backup)_$(date +%Y%m%d)_$cleanedcomment.tgz" $directory2backup
  else
    echo -e "Starting encrypted backup of ${GREEN}$directory2backup${RESET}. "
    tar czvpf - $(directory2backup) | gpg --batch --passphrase "$(backuppassword)" --symmetric --cipher-algo aes256 -o $(directory2backup)_$(date +%Y%m%d)_$cleanedcomment.tar.gz.gpg
  fi
else 
  # do a restore
  if [[ -z "$backuppassword" ]];
  then
    echo -e "Starting restore of ${GREEN}$directory2backup${RESET}. "
    tar xvfz -C $targetdirectory ${clp_restore} $directory2backup
  else
    echo -e "Starting restore of ${GREEN}$directory2backup${RESET}. "
    gpg --batch --yes --passphrase "$(backuppassword)" -d ${clp_restore}  |tar xzvf -C $targetdirectory -
  fi
fi  

echo -e "out of the loop"
#secure backup 	tar czvpf - file1.txt file2.pdf file3.jpg | gpg --batch --passphrase "$(backuppassword)--symmetric --cipher-algo aes256 -o myarchive.tar.gz.gpg
#secure restore 	gpg -d myarchive.tar.gz.gpg | tar xzvf -
#tar czvpf - scripts | gpg --batch --passphrase "ollekebolleke is het woord" --symmetric --cipher-algo aes256 -o scripts.tar.gz.gpg
#tar cvfz "$1_$(date +%Y%m%d)_$2.tgz" $1

