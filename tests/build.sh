#!/bin/bash

## HELP
usage="Usage: $0 -j [job_name] -b [build_parameters] \n
Options: \n
    -q query the newly created job and output the json content \n
    -p jenkins port \n 
    -v enable curl verbose \n
    -P print curl output and cmd \n
    -h help
/!\ Jenkins' token must be stored in token.txt
"

## PARAMETERS
declare -A parameters=(
    ["job"]=""
    ["build_parameters"]="GITHUB_NAME=Julian52575/Hylozoa-Engine-Engine&GIT_BRANCH=dev"
    ["query"]=false
    ["print"]=false
    ["verbose"]=false
    ["port"]='8080'
)

while getopts "hvPq""j:p:b:" opt; do
  case $opt in
    j) parameters["job"]="$OPTARG" ;;
    b) parameters["build_parameters"]="$OPTARG" ;;
    q) parameters["query"]=true ;;
    v) parameters["verbose"]=true ;;
    p) parameters["port"]="$OPTARG" ;;
    P) parameters["print"]=true ;;
    h) echo -e $usage && exit 0 ;;
    *) echo "Invalid option"; exit 1 ;;
  esac
done

if [ ${parameters["verbose"]} == true ]; then
    for param in "${!parameters[@]}"; do
        echo -e "parameter[$param]=${parameters[$param]}" | cat -e
    done
fi

if [ -z ${parameters["job"]} ]; then
    echo "Error: missing parameter -j <job>" >&2
    echo -e $usage >&2
    exit 84
fi
## TOKEN READ
token_file=$(find . tests/ -maxdepth 1 -iname "token.txt" | head -n 1)

if [ ! -f "$token_file" ]; then
    echo "Error: token.txt not found. Please copy-paste your jenkins api token there." >&2
    exit 84
fi

token=$(tr -d '\r\n' < "$token_file")

if [ -z "$token" ]; then
    echo "Error: empty token." >&2
    exit 84
fi

## CURL
curl_cmd=(
  curl -i -f -X POST
  "http://localhost:${parameters[port]}/job/${parameters[job]}/buildWithParameters?${parameters[build_parameters]}"
  --user "webhook:${token}"
)

if [ ${parameters[verbose]} == true ]; then
    curl_cmd+=(--verbose)
fi

## CMD Print
if [ ${parameters[print]} == true ]; then
    masked_cmd=()
    skip_next=0

    for arg in "${curl_cmd[@]}"; do
      if [ "$skip_next" -eq 1 ]; then
        masked_cmd+=("*:*")
        skip_next=0
        continue
      fi

      if [ "$arg" = "--user" ]; then
        masked_cmd+=("--user")
        skip_next=1
      else
        masked_cmd+=("$arg")
      fi
    done
    printf '%q ' "${masked_cmd[@]}"
    echo
fi
## CMD Print

set -o pipefail
REPLY="$("${curl_cmd[@]}" | cat)"
STATUS=$?

if [ ${parameters[print]} == true ]; then
    echo "REPLY:"
    echo "$REPLY"
fi

if [[ $STATUS -ne 0 ]] then
    echo "Error: curl returned non-zero."
    exit $STATUS
fi
## LOCATION CHECK
LOCATION=$(echo "$REPLY" | grep -i Location | awk '{print $2}' | tr -d '\r')

if [ -z "$LOCATION" ]; then
    echo "Error: No 'location' header received. The request probably failed on Jenkins' side... :(" >&2
    echo "Double check the job name as well as the api token." >&2
    exit 1
fi
if [ ${parameters[query]} == false ]; then
    echo "Track progress at ${LOCATION}api/json"
    exit 0
fi

## QUERY
id=${LOCATION#*/item/}
id=${id%%/*}
query_script=$(find . tests/ -maxdepth 1 -iname "query.sh" | head -n 1)

if [ ! -f "$query_script" ]; then
    echo "Error: query.sh not found. Run this script at root or inside tests/" >&2
    exit 84
fi
query_cmd=(
    bash "$query_script" -i "$id" 
)

if [ ${parameters[verbose]} == true ]; then
    query_cmd+=(-v)
fi
if [ ${parameters[print]} == true ]; then
    query_cmd+=(-P)
    printf '%q ' "${query_cmd[@]}"
    echo
fi
REPLY="$("${query_cmd[@]}" | cat)"