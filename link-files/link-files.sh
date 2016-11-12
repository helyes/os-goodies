#!/bin/bash
################################################################################################################
# Symlinking utility file driven by a configuration file.                                                      #
#                                                                                                              #
# The main purpose is to keep certain files in one spot that can be managed by github                          #
#                                                                                                              #
# Example config:                                                                                              #
#~/.profile=~/.config/tracked                                                                                  #
#~/.bashrc=~/.config/tracked                                                                                   #
################################################################################################################

CONFIG_FILE=$1

function usage {
	echo
	echo "Usage : $0 <config file>"
  echo
  echo "Example:"
  echo "  $0 userdotfiles.conf"
  echo
  echo "  Userdotfiles.conf layout"
  echo "  <file>=<source folder>"
  echo
  echo "  file : the symlink"
  echo "  source folder : the file origin folder"
  echo
  echo "  Example"
  echo "  -------------------------"
  echo "  ~/.profile=~/secret/user"
  echo "  ~/.bashrc=~/secret/user"
  echo "  -------------------------"
  echo "  Will result in "
  echo "  ~/.profile pointing to ~/secret/user/.profile"
  echo "  ~/.bashrc pointing to ~/secret/user/.bashrc"
  exit 2;
}

if [ "$#" -ne 1 ]; then
    usage
fi

function fatal {
  printf "\033[0;31mFATAL: ${1}. Giving up\033[0m";
  exit 1
}

#array contains config key - values
files=()

function readConfigFile {
  printf "\n\033[1;37mParsing config file: ${CONFIG_FILE}\033[0m\n\n"
  if [ ! -f "$CONFIG_FILE" ]
  then
    fatal "${CONFIG_FILE} does not exist"
  fi

  while IFS='=' read -r key value
  do
      #skip comments - lines start with # and empty lines
      if [[ "$key" =~ ^#.*$ ]] || [[ -z "${key// }" ]]
      then
         continue
      fi
      echo "$key : $value"

      files+=($key)
      files+=($value)
  done < "$CONFIG_FILE"
  echo
  if [ $((${#files[@]}%2)) -eq 1 ]; then
    printf '%s : ' "${files[@]}"
    fatal "\nCould not parse config file. Most likely a key or a value is empty. See parsed elements above"
  fi
  printf "\033[0;32mSuccess: ${CONFIG_FILE} loaded\033[0m\n\n";
}

readConfigFile

# sanity checks and quick fixes
function sanityCheck {

 #target directory exists
 DESTINATION=$1
 SOURCE=$2

 #file is not empty
 if  [[ -z "${DESTINATION// }" ]]; then
   fatal "File is empty for ${SOURCE}"
 fi

 if [ ! -f "$SOURCE" ]; then
   fatal "File ${SOURCE} does not exist"
 fi

 DESTINATION_FOLDER=$(dirname "${DESTINATION}")
 if [ ! -d "$DESTINATION_FOLDER" ]; then
   echo "Creating directory: ${DESTINATION_FOLDER}"
   mkdir -pv ${DESTINATION_FOLDER}
 fi

 if [ ! -w $DESTINATION_FOLDER ] ; then
  fatal "$DESTINATION_FOLDER folder is not writeable by $USER"
 fi

}

for ((i=0;i<${#files[@]};i+=2))
do
  DESTINATION_RAW=${files[$i]}
  SOURCE_FOLDER_RAW=${files[$i+1]}

  #expand paths, ~/file.txt -> /User/joe/file.txt
  eval SOURCE_FOLDER=$SOURCE_FOLDER_RAW
  eval DESTINATION=$DESTINATION_RAW

  if [[ "$SOURCE_FOLDER" != */ ]]
  then
      TO="$SOURCE_FOLDER/";
  fi

  DESTINATION_NAME=${DESTINATION##*/}
  SOURCE_FILE=${SOURCE_FOLDER}/${DESTINATION_NAME}

  #echo "SOURCE_FILE: ${SOURCE_FILE}"
  #echo "DESTINATION: ${DESTINATION}"

  sanityCheck $DESTINATION $SOURCE_FILE

  #printf "Symlinking ${SOURCE_FILE} to ${DESTINATION}\n";
  COMMAND="ln -sfv ${SOURCE_FILE} ${DESTINATION}"
  echo "Executing ${COMMAND}"
  eval $COMMAND

  lnExitCode=$?

  if [ ${lnExitCode} -ne 0 ]; then
    fatal "Could not link ${DESTINATION}to ${SOURCE_FILE}"
  else
    printf "\033[0;32mSuccess: ${DESTINATION} -> ${SOURCE_FILE}\033[0m\n\n";
  fi

done
