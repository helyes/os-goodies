#!/bin/bash
################################################################################################################
# Symlinking utility file driven by a configuration file.                                                      #
#                                                                                                              #
# The main purpose is to keep certain files in one spot that can be managed by github                          #
#                                                                                                              #
# Example config:                                                                                              #
# ~/.profile=~/.config/tracked                                                                                  #
# ~/.bashrc=~/.config/tracked                                                                                   #
################################################################################################################


###########################################################
#                                                         #
# Manual                                                  #
#                                                         #
###########################################################
function usage {
	echo
	echo "Usage : $0 [link|init] <config file>"
  echo
  echo "Example:"
  echo
  echo "  Userdotfiles.conf layout"
  echo "  <link>=<source folder>"
  echo
  echo "  link          : the symlink. Will point to <source folder>/link"
  echo "  source folder : the file origin folder"
  echo
  echo "  Example config file"
	echo "  -------------------------"
  echo "  ~/.profile=~/config/user/"
  echo "  ~/.bashrc=~/config/user"
  echo "  -------------------------"
	echo
	echo " $0 link userdotfiles.conf"
  echo
  echo "  Will result in "
  echo "  /Users/john/.profile pointing to /Users/john/config/user/.profile"
  echo "  /Users/john/.bashrc pointing to /Users/john/config/user/.bashrc"
	echo
	echo " $0 init userdotfiles.conf"
  echo
  echo "  Will copy"
  echo "  /Users/john/.profile to /Users/john/config/user/.profile"
  echo "  /Users/john/.bashrc to /Users/john/config/user/.bashrc"
  echo

	if [ "$1" == "noquit" ]
	then
		return
	else
		exit 2
	fi


}

# must pass two parameters
if [ "$#" -ne 2 ]; then
    usage
fi

ACTION=$1
CONFIG_FILE=$2

###########################################################
#                                                         #
# Log fatal error and exit with <> 0                      #
#                                                         #
###########################################################
function fatal {
  printf "\033[0;31m\nFATAL: ${1}.\nGiving up\033[0m";
	echo
  exit 1
}

#array contains config key - values
files=()


###########################################################
#                                                         #
# Read config file line by line and populate files array  #
#                                                         #
# even elements: the symlink                              #
# odd elements: the source file the link will point to    #
#                                                         #
###########################################################
function readConfigFile {
  printf "\n\033[1;37mParsing config file: ${CONFIG_FILE}\033[0m\n\n"

	if [ ! -f "$CONFIG_FILE" ]
  then
    fatal "${CONFIG_FILE} does not exist"
  fi

  while IFS='=' read -r key value
  do
      #skip comments - lines start with #
			#skip empty lines
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


###########################################################
#                                                         #
# Sanity checks and quick fixes for linking               #
#                                                         #
###########################################################
function sanityCheckLink {

 #target directory exists
 DESTINATION=$1
 SOURCE=$2

 #file is not empty
 if  [[ -z "${DESTINATION// }" ]]; then
   fatal "File is empty for ${SOURCE}"
 fi

 # source file exist
 if [ ! -f "$SOURCE" ]; then
   fatal "File ${SOURCE} does not exist"
 fi

 # create destination's file folder if it does not exist
 DESTINATION_FOLDER=$(dirname "${DESTINATION}")
 if [ ! -d "$DESTINATION_FOLDER" ]; then
   echo "Creating directory: ${DESTINATION_FOLDER}"
   mkdir -pv ${DESTINATION_FOLDER}
 fi

 # permission check
 if [ ! -w $DESTINATION_FOLDER ] ; then
  fatal "$DESTINATION_FOLDER folder is not writeable by $USER"
 fi

}

###########################################################
#                                                         #
# Sanity checks and quick fixes for init                  #
#                                                         #
###########################################################
function sanityCheckInit {

 #target directory exists
 DESTINATION=$1
 SOURCE=$2

 #file is not empty
 if  [[ -z "${DESTINATION// }" ]]; then
   fatal "File is empty for ${SOURCE}"
 fi

 # source file exist
 if [ ! -f "$SOURCE" ]; then
   fatal "File ${SOURCE} does not exist"
 fi

 # source file readable
 if [ ! -r $SOURCE ] ; then
  fatal "File $SOURCE is not readable by $USER"
 fi

 # source file writeable
 if [ ! -w $SOURCE ] ; then
  fatal "File $SOURCE is not writable by $USER"
 fi

 # create destination's file folder if it does not exist
 DESTINATION_FOLDER=$(dirname "${DESTINATION}")
 if [ ! -d "$DESTINATION_FOLDER" ]; then
   fatal "Destiantion directory does not exist: ${DESTINATION_FOLDER}\nRun \n mkdir -pv ${DESTINATION_FOLDER}"
 fi

 # permission check
 if [ ! -w $DESTINATION_FOLDER ] ; then
  fatal "$DESTINATION_FOLDER folder is not writeable by $USER"
 fi

 # destination file already exists
 if [ -f "$DESTINATION" ]; then
   fatal "File ${DESTINATION} already exists. Overwrite is not allowed for safety reasons"
 fi

}


###########################################################
#                                                         #
# Symlinks files acording to config file                  #
#                                                         #
###########################################################
function link {
	printf "\n\033[1;37mLinking files...\033[0m\n\n"
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

	  sanityCheckLink $DESTINATION $SOURCE_FILE

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
}

###########################################################
#                                                         #
# Copies files into configured folder                     #
#                                                         #
###########################################################
function init {
	printf "\n\033[1;37mInitializing...\033[0m\n\n"

	for ((i=0;i<${#files[@]};i+=2))
	do

	  SOURCE_RAW=${files[$i]}
	  DESTINATION_FOLDER_RAW=${files[$i+1]}


	  #expand paths, ~/file.txt -> /User/joe/file.txt
	  eval DESTINATION_FOLDER=$DESTINATION_FOLDER_RAW
	  eval SOURCE=$SOURCE_RAW

		echo "DESTINATION_FOLDER: ${DESTINATION_FOLDER}"
	  if [[ "$DESTINATION_FOLDER" != */ ]]
	  then
	      DESTINATION_FOLDER="$DESTINATION_FOLDER/";
	  fi

	  DESTINATION_NAME=${SOURCE##*/}
	  DESTINATION=${DESTINATION_FOLDER}${DESTINATION_NAME}

		echo "SOURCE: ${SOURCE}"
	  echo "DESTINATION: ${DESTINATION}"


	  sanityCheckInit $DESTINATION $SOURCE


	  #printf "Symlinking ${SOURCE_FILE} to ${DESTINATION}\n";
	  COMMAND="mv -v ${SOURCE} ${DESTINATION}"
	  echo "Executing ${COMMAND}"
	  eval $COMMAND

	  cpExitCode=$?

	  if [ ${cpExitCode} -ne 0 ]; then
	    fatal "Could not move ${SOURCE} to ${DESTINATION}"
	  else
	    printf "\033[0;32mSuccess: ${SOURCE} moved to ${DESTINATION}\033[0m\n\n";
	  fi

	done

}


case "$ACTION" in
  init|i|INIT|I)
	   readConfigFile
		 init
     ;;
  link|l|LINK|L)
		 readConfigFile
		 link
     ;;
  *) usage noquit
	   fatal "Unknown parameter $ACTION"
     ;;
esac
