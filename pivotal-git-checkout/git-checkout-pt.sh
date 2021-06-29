#!/bin/bash
#
# Git plugin to create branch for a given pt ticket. See usage.
#
# Easiest use is to click on "ID" on pt to put ticket number on clipboard then `git ptbranch`
# Output:
# Branch pt-1234567890-my-great-feature-request does not exists. Creating
# Copying git command to clipboard:
# git checkout -b pt-1234567890-my-great-feature-request
#
# Now all you need is paste clipboard and hit enter.


# These values below can be hardcoded here, i am personally using the ctae (https://github.com/helyes/os-goodies/blob/master/ssh-to-aws-ec2/ctae.sh) script so i can push all my scripts without worrying about secrets.
# pivotal project id grab it from the end of url: https://www.pivotaltracker.com/n/projects/<project id>
PIVOTAL_PROJECT_ID=$(ctae.sh -g pivotal_project_id)
# create an api token on https://www.pivotaltracker.com/profile and chuck it below
PIVOTAL_API_TOKEN=$(ctae.sh -g pivotal_api_token)

usage () {
  printf "\\nUsage:\\n\\n"
  printf "%s [-t|--ticketid <ticket id>] [-u|--url <ticket url>] [-p|--print] [-h|--help] \\n\\n" "$0"
  printf "\\t-t: pivotal ticket id (if starting with hash parmaeter must be quoted as \"#12121212\")\\n"
  printf "\\t    may be branch name as long as it starts with pt-\\n"
  printf "\\t-c: copies git command to clipboard only, not executing it\\n"
  printf "\\t-u: pivotal ticket url\\n"
  printf "\\t-d: dry mode, will not create/change branch, only printing the command\\n"  
  printf "\\t-h: print help\\n\\n"
  printf "Github setup\\n\\n"
  echo "Add below block to ~/.gitconfig"
  echo "[alias]"
  # shellcheck disable=SC2016
  printf '  ptbranch = \"! git-checkout-pt.sh -c -t \\"$(pbpaste)\\\""\n'
  exit 9
}

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -t|--ticketid)
      TICKET_ID_OR_BRANCH="$2" # this may be ticket id as "#121212121" OR branch name as pt-1241241-my-awesome-feature
      shift # argument
      shift # value
      ;;
      -u|--url)
      TICKET_URL="$2"
      shift # argument
      shift # value
      ;;
      -c|--clipboard)
      CLIPBOARD_ONLY=1
      shift # argument
      ;;
      -d|--dry)
      PRINT_ONLY=1
      shift # argument
      ;;
      *)    # unknown options
      shift # argument
      ;;
  esac
done

if [[ -z "$TICKET_ID_OR_BRANCH" && -z "$TICKET_URL" ]]; then
  printf "\\nTicket url or ticket id must be passed as parameter\\n"
  usage
fi

# Checks if given parameters are executable. Accepts multiple parameters.
# 
# To check if aws and ls commands are installed, call it as 'check_installed_dependencies aws ls'
check_installed_dependencies() {
  numargs=$#
  for ((i=1 ; i <= numargs ; i++))
  do
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "Script requires '$1' but it's not installed. Aborting."; exit 1; }
    shift
  done
}

check_installed_dependencies curl jq pbpaste

parse_ticket_number() {
  local RET=""
  if [ -n "${TICKET_ID_OR_BRANCH}" ]; then
    RET=$(tr -d '#' <<< "${TICKET_ID_OR_BRANCH}")
  elif [ -n "${TICKET_URL}" ]; then
    RET="${TICKET_URL##*/}"
  else
    printf "\\n\\nCan't parse ticket number\\n"
    usage
  fi
  echo "$RET"
}

get_branch_name() {
  local RET=""
  if [[ "$TICKET_ID_OR_BRANCH" == https* ]] ;
  then
    RET="ERROR_1"
  elif [[ "$TICKET_ID_OR_BRANCH" == pt-* ]] ;
  then
    RET="$TICKET_ID_OR_BRANCH"
  else
    TICKET_NUMBER=$(parse_ticket_number)
    #STORY_DESCRIPTION="Let's have Some garbage !@#$^%&()* here"
    STORY_DESCRIPTION=$(curl -s -X GET -H "X-TrackerToken: ${PIVOTAL_API_TOKEN}" "https://www.pivotaltracker.com/services/v5/projects/${PIVOTAL_PROJECT_ID}/stories/${TICKET_NUMBER}" | jq .name)
    STORY_DESCRIPTION_NORMALIZED=$(echo "${STORY_DESCRIPTION}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]_-')
    RET="pt-${TICKET_NUMBER}-${STORY_DESCRIPTION_NORMALIZED:0:60}"
  fi
  echo "$RET"
}


BRANCH_NAME=$(get_branch_name)
if [[ "$BRANCH_NAME" == ERROR_1 ]]
then
    echo "You most likely put the ticket url on clipboard, not the ticket number (#1231424 format). Click ID on pivotal"
    exit 1
fi

if [[ "$BRANCH_NAME" =~ ( |\') ]]
then
   echo "Branch name seems to include spaces. Clipboard should hold only ticket number, url or branchname. Aborting"
   echo "Branch name: $BRANCH_NAME"
   usage
fi

is_branch_exists_remote() {
    local branch=${1}
    local in_remote
    in_remote=$(git ls-remote --heads origin "${branch}")
    if [[ -z ${in_remote} ]]; then
        echo 0
    else
        echo 1
    fi
}

# Check if branch exist locally and on remote. -b flag depends on it
if [ "$(git branch --list "$BRANCH_NAME")" ]
then
  printf "\\nBranch %s exists locally. Simple checkout\\n\\n" "$BRANCH_NAME"
  COMMAND="git checkout ${BRANCH_NAME}"
else
  # branch does not exist on localhost. Check if it does on remote
  if [ "$(is_branch_exists_remote "${BRANCH_NAME}")" -eq 0 ]; then
    printf "\\nBranch %s does not exists. Creating\\n\\n" "$BRANCH_NAME"
    COMMAND="git checkout -b ${BRANCH_NAME}"
  else
    printf "\\nFound branch %s in remote, simple checkout\\n\\n" "$BRANCH_NAME"
    COMMAND="git checkout ${BRANCH_NAME}"
  fi
fi

if [ -n "${PRINT_ONLY}" ]; then
  printf "Printing only, would execute:\\n\\n"
  echo "$COMMAND"  
elif [ -n "${CLIPBOARD_ONLY}" ]; then
  printf "Copying git command to clipboard:\\n\\n"
  echo "$COMMAND" | tr -d '\n' | pbcopy
  echo "$COMMAND"
else
  echo "Executing..."
  ${COMMAND}  
fi

exit 0;
