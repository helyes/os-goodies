#!/bin/bash
#
# Deletes branches that are merged into master branch
#
# Todo: create functions to make it more human. It started as a one liner and gradually escalated to this
# Listing stale branches
#  for branch in `git branch -r | grep -v HEAD`;do echo -e `git show --format="%ci %cr" $branch | head -n 1` \\t$branch; done | sort -r



# Branches to exlude from delete
#INTOUCHABLES="master, develop, production, hotfix/.*, pilot, shiftcare_development, release.*"
INTOUCHABLES="master, develop, production, hotfix/.*, pilot, shiftcare_development"

usage () {
  printf "\\nUsage:\\n\\n"
  printf "%s -m|--main main branch [-f|--filter branch filter] [-d|--dry dry run[ [-l|--local] local branches only [-h|--help print this help] \\n\\n" "$0"
  printf "\\t-m: name of the main branch. The branch where all branches should be merged\\n"
  printf "\\t-f: only branches matches this filter will be listed. -f=fix, update will check branhces only with the word fix or update in branch name\\n"
  printf "\\t-d: dry run, echo only\\n"
  printf "\\t-l: checks local branches only only\\n"
  printf "\\t-h: print help\\n\\n"
  printf "Note: Keep in mind that git can not delete the branch it is currently sitting. Checkout main branch\\n"
  printf "      Check INTOUCHABLES variable in script to see what branches are exlcuded from delete\\n\\n"
  exit 9
}

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -m|--main)
      MAIN_BRANCH="$2"
      shift # argument
      shift # value
      ;;
      -f|--filter)
      FILTER="$2"
      shift # argument
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
      -l|--local)
      LOCAL_ONLY=1
      shift # value
      ;;
      *)    # unknown options
      shift # argument
      ;;
  esac
done

if [ -z "$MAIN_BRANCH" ]; then
  printf "Main (-m|--main) parameter is mandatory\\n\\n"
  usage
fi

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

checkInstalledDependencies "git"

# build GREP_EXCLUDE_REGEX regex from $INTOUCHABLES set on the top
IFS=', ' read -r -a INTOUCHABLES_ARRAY <<< "${INTOUCHABLES}"
for index in "${!INTOUCHABLES_ARRAY[@]}"
do
  INTOUCHABLE=${INTOUCHABLES_ARRAY[index]} 
  GREP_EXCLUDE_REGEX=${GREP_EXCLUDE_REGEX}${INTOUCHABLE}\\\|
done
GREP_EXCLUDE_REGEX="${GREP_EXCLUDE_REGEX}\\*"

# build FILTER_REGEX regex passed by filter param. If nothing passed, regex = .*
if [ -n "$FILTER" ]; then
  IFS=', ' read -r -a FILTER_ARRAY <<< "${FILTER}"
  for index in "${!FILTER_ARRAY[@]}"
  do
    F=${FILTER_ARRAY[index]} 
    FILTER_REGEX=${FILTER_REGEX}${F}\\\|
  done
  FILTER_REGEX="${FILTER_REGEX}\\*"
else
  FILTER_REGEX=".*"
fi


if [ -z "$LOCAL_ONLY" ]; then
  REMOTE_FLAG=-a
fi

MERGED_BRANCHES=$(git branch ${REMOTE_FLAG} --merged "${MAIN_BRANCH}" | grep -v -e "${GREP_EXCLUDE_REGEX}" | grep "${FILTER_REGEX}")

printf "\\nBranches merged into %s\\n\\n" "${MAIN_BRANCH}"
echo "${MERGED_BRANCHES}"

LINES=$(echo "$MERGED_BRANCHES" | wc -l)


if [ "$LINES" -eq "1" ]; then
    MERGED_BRANCHES_NORMALIZED=$MERGED_BRANCHES
else 
    # removing duplicated whitespaces - dont quote ${MERGED_BRANCHES}
    MERGED_BRANCHES_NORMALIZED=$(sed -n '/.*/s/  */ /gp' <<< ${MERGED_BRANCHES})    
fi
 
#loading branches into an array
IFS=', ' read -r -a array <<< "${MERGED_BRANCHES_NORMALIZED}"

NO_OF_REMOTE_BRANCHES=$(echo "${MERGED_BRANCHES}" | grep -o  origin  | wc -l)
NO_OF_LOCAL_BRANCHES=$((${#array[@]}-NO_OF_REMOTE_BRANCHES))

printf "\\nFound %d branches merged into %s. %d remote and %d local\\n\\n" "${#array[@]}" "${MAIN_BRANCH}" "$NO_OF_REMOTE_BRANCHES" "$NO_OF_LOCAL_BRANCHES"

if [ "${#array[@]}" = "0" ]; then
    echo "Nothing to do, exiting"; 
    exit 0;
fi

read -rp "Delete these branches (y/n)? " confirm

if [ "$confirm" != "y" ]; then 
  echo "Aborting" && exit 9; 
fi

echo

for index in "${!array[@]}"
do
  BRANCH=${array[index]} 
  printf "[%d/%d] Deleting branch " $((index+1)) ${#array[@]}

  # different path for local/remote branches
  if [[ $BRANCH = *"remotes/origin"* ]]; then
    printf "[REMOTE]: %s\\n" "$BRANCH"
    REMOTE_BRANCH=${BRANCH#*remotes/origin/}
    COMMAND="git push -d origin ${REMOTE_BRANCH}"
  else
    printf "[LOCAL]: %s\\n" "$BRANCH"
    COMMAND="git branch -d ${BRANCH}"
  fi

  # dry mode prints only
  if [ -n "${DRY}" ]  ; then
    echo "Dry run, would execute: ${COMMAND}"
  else
    echo "Executing: ${COMMAND}"
    ${COMMAND}  
  fi
  retVal=$?    
  echo
  if [ $retVal -ne 0 ]; then
    echo "Failed to delete branch ${BRANCH}"
  fi
done

exit 0;
