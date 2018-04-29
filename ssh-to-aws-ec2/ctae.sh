#!/bin/bash
#
# SSH to amazon ec2 instances.
# Connection shortcuts can be configured in a config file, please run script with -s parameter to generate a sample config file
 
# Default config file
CONFIG_FILE=./ctae.cfg

usage () {
  printf "\\nUsage:\\n\\n"
  printf "%s -i|--instance instance to connect [-l|--list list configured hosts] [-c|--config config file location] [-p|privatekey private key location] [-u|username ec2 username] [-h|--help print help] \\n\\n" "$0"
  printf "\\t-i: the instance to connect to. Must present in config file as key\\n"
  printf "\\t-l: lists configured instances\\n"
  printf "\\t-c: config file, defaults to ./ctae.cfg\\n"
  printf "\\t-p: private key file path\\n"  
  printf "\\t-u: ec2 user name\\n"
  printf "\\t-s: generate sample config file\\n"
  printf "\\t-h: print help\\n\\n"
  printf "Note: Command line parameters override settings in config file\\n\\n"
  printf "This script depends on aws-cli. Install it as 'brew install awscli'\\n\\n"
  exit 9
}

# Check if given files exist and exits at first non existent file
#
# Accepts, multiple parameters. Check if ./foo and ./bar exist as 'checkFilesExist ./foo ./bar'
checkFilesExist () {
  numargs=$#
  for ((i=1 ; i <= numargs ; i++))
  do
    #echo "Checking '$1'... "
    if [ ! -f "$1" ]; then
        echo "File $1 does not exist."
        exit 1;
    fi
    shift
  done
}

createSampleConfig () {
  CONFIG_FILENAME=$(basename -- "$CONFIG_FILE")
  CONFIG_BASENAME="${CONFIG_FILENAME%.*}"
  CONFIG_EXTENSION="${CONFIG_FILENAME##*.}"
  SAMPLE_CONFIG_FILE="$(dirname "$CONFIG_FILE")/${CONFIG_BASENAME}.sample.${CONFIG_EXTENSION}"
  
  printf "\\nGenerating sample config file: %s\\n\\n" "$SAMPLE_CONFIG_FILE"
  if [ -f "$SAMPLE_CONFIG_FILE" ]; then
    printf "File %s already exists. Moving " "${SAMPLE_CONFIG_FILE}"
    mv -v "${SAMPLE_CONFIG_FILE}" /tmp/
  fi

  {
    echo "# Config for ctae.sh" > "${SAMPLE_CONFIG_FILE}"
    echo "# Spaces are not allowed front of keys."
    echo ""; echo ""
    echo "# General config"
    echo ""
    echo "CONFIG_PRIVATE_KEY_FILE=/Users/foo/.ssh/aws-secret.pem"
    echo "CONFIG_EC2_USER_NAME=foexamplecom"
    echo ""
    echo "# Prod instances"
    echo "prd-app1=i-12345678901234567"
    echo "prd-app2=i-22345678901234567"
    echo ""
    echo "# Staging instances"
    echo "stg-app1=i-42345678901234567"
    echo "stg-app2=i-52345678901234567"
    echo ""
  }  >> "${SAMPLE_CONFIG_FILE}"

  printf "\\n\\nDone:"
  printf "\\n-----\\n\\n"
  cat "${SAMPLE_CONFIG_FILE}"
}


# Returns all configured instances in config file
listConfiguredInstances () {
  printf "\\nConfigured instances:\\n\\n"
  grep -v "#" "${CONFIG_FILE}" | grep -v "CONFIG" | grep .
  exit 0
}

# Checks if given parameters are executable. Accepts multiple parameters.
# 
# To check if aws and ls commands are installed, call it as 'checkInstalledDependencies aws ls'
checkInstalledDependencies () {
  numargs=$#
  for ((i=1 ; i <= numargs ; i++))
  do
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "Script requires '$1' but it's not installed. Aborting."; exit 1; }
    shift
  done
}

checkInstalledDependencies "aws"

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -i|--instance)
      INSTANCE="$2"
      shift # argument
      shift # value
      ;;
      -c|--config)
      CONFIG_FILE="$2"
      shift # argument
      shift # value
      ;;
      -p|--privatekey)
      PRIVATE_KEY_FILE="$2"
      shift # argument
      shift # value
      ;;
      -u|--user)
      EC2_USER_NAME="$2"
      shift # argument
      shift # value
      ;;
      -l|--list)
      listConfiguredInstances
      shift # value
      ;;    
      -h|--help)
      usage
      shift # value
      ;;    
      -d|--dry-run)
      DRY=1
      shift # value
      ;;
      -s|--sampleconfig)
      createSampleConfig
      exit 0
      ;;    
      *)    # unknown options
      shift # argument
      ;;
  esac
done

checkFilesExist "${CONFIG_FILE}"

if [ -z "$INSTANCE" ]; then
  printf "Instance parameter is mandatory\\n\\n"
  usage
fi

getConfigValueForKey () { 
  CONFIG_ENTRY=$(grep -v "#" "${CONFIG_FILE}" | grep "^$1")
  local VALUE=${CONFIG_ENTRY#*=}   
  echo "$VALUE"
}

if [ -z "$PRIVATE_KEY_FILE" ]; then
  PRIVATE_KEY_FILE=$(getConfigValueForKey  "CONFIG_PRIVATE_KEY_FILE")
fi

if [ -z "$EC2_USER_NAME" ]; then
  EC2_USER_NAME=$(getConfigValueForKey  "CONFIG_EC2_USER_NAME")
fi

checkFilesExist "${PRIVATE_KEY_FILE}"

printf "Loading config file: %s\\n\\n" "${CONFIG_FILE}"

INSTANCE_ID=$(getConfigValueForKey  "${INSTANCE}")

if [ -z "${INSTANCE_ID}" ]  ; then
  printf "Instance '%s' is not configured in %s. Aborting.\\n\\n" "${INSTANCE}" "${CONFIG_FILE}"
  exit 2
fi

if [ -z "${EC2_USER_NAME}" ]  ; then
  printf "EC2_USER_NAME is not configured. Please add it to config file as CONFIG_EC2_USER_NAME or pass it as a parameter. Aborting.\\n\\n"
  exit 2
fi

printf "Connecting to instance %s / %s as %s\\n" "${INSTANCE}" "${INSTANCE_ID}" "${EC2_USER_NAME}"

COMMAND="ssh -i ${PRIVATE_KEY_FILE} ${EC2_USER_NAME}@$( aws ec2  describe-instances --instance-ids "${INSTANCE_ID}" | grep "PublicIpAddress" | grep -o "[0-9\\.]\\+")"

if [ -n "${DRY}" ]  ; then
  printf "\\nDry run. Would execute:\\n\\n"
  echo "$COMMAND"  
else
  ${COMMAND}  
fi

exit 0;
