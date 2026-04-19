#!/bin/bash

## HELP
usage="Usage: $0 -i [job id] \n
Options: \n
    -j job name (defaults to querying 'queue/item')
    -p jenkins port \n 
    -v enable curl verbose \n
    -P print curl cmd \n
    -h help
/!\ Jenkins' token must be stored in token.txt
"

## PARAMETERS
declare -A parameters=(
    ["id"]=""
    ["job"]="queue/item"
    ["port"]='8080'
    ["verbose"]=false
    ["print"]=false
)

while getopts "hvP""i:p:j:" opt; do
  case $opt in
    i) parameters["id"]="$OPTARG" ;;
    j) parameters["job"]="job/""$OPTARG" ;;
    p) parameters["port"]="$OPTARG" ;;
    v) parameters["verbose"]=true ;;
    P) parameters["print"]=true ;;
    h) echo -e $usage && exit 0 ;;
    *) echo "Invalid option"; exit 1 ;;
  esac
done

if [ -z ${parameters["id"]} ]; then
    echo "Error: missing parameter -i [id]"
    echo -e $usage
    exit 84
fi

## TOKEN READ
token_file=$(find . tests/ -maxdepth 1 -iname "token.txt" | head -n 1)

if [ ! -f "$token_file" ]; then
    echo "Error: token.txt not found. Please copy-paste your jenkins api token there."
    exit 84
fi

token=$(tr -d '\r\n' < "$token_file")

if [ -z "$token" ]; then
    echo "Error: empty token."
    exit 84
fi
## CURL
curl_cmd=(
  curl -f -X GET
  "http://localhost:${parameters[port]}/${parameters[job]}/${parameters[id]}/api/json"
  --user "webhook:${token}"
)
if [ ${parameters[verbose]} == true ]; then
    curl_cmd+=(--verbose)
fi

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

set -o pipefail
REPLY="$("${curl_cmd[@]}" | cat)"
STATUS=$?

if [[ $STATUS -eq 0 ]] then
    echo "$REPLY" | jq
else
    echo "Error: curl returned non-zero."
fi
