#!/bin/bash

function export {
  declare -A index
  results=()
  i=0
  while read -r input
  do

      name=$(echo $input | jq -r '@html "\(.name)"' | sed -e 's/\([\\^*+\.$\\/&-]\)/\\\1/g')
      desc=$(echo $input | jq -r '@html "\(.desc)"' | sed -e ':a;N;$!ba;s:\n:<br />:g' -e 's/\([\\^*+\.$\\/&-]\)/\\\1/g')
      cost=$(echo $input | jq -r '@html "\(.cost)"' | sed -e 's/\([\\^*+\.$\\/&-]\)/\\\1/g')
      color=$(echo $input | jq -r '@html "\([.labels[] | select(.name | test("sprint"; "i") | not)] | first(.[]).color)"' | sed -e 's/\([\\^*+\.$-\\/&]\)/\\\1/g')
      debt=$( if ( $(echo $input | jq -r '[.labels[] | contains({name: "Tech Debt"})] | any') ); then echo "red"; else echo "$color"; fi)

      ((index[$color]=index[$color]+1))
      
      results[$i]=$(sed -e "s/###CardTitle###/$name/" \
                        -e "s/###CardDesc###/$desc/" \
                        -e "s/###CardValue###/$cost/" \
                        -e "s/###CardColor###/$color/" \
                        -e "s/###CardDebt###/$debt/" \
                        -e "s/###CardCount###/#${index[$color]}/" \
                        "$ROOT/template.$DISPLAY.html")
      ((i=i+1))
  done

  count=${#results[*]}
  start=0
  end=$((count))
  
  if [[ $HEAD -ge 0 ]]
  then
    end=$HEAD
    if [[ $TAIL -ge 0 ]]
    then
      start=$(( $HEAD - $TAIL ))
    fi
  else
    if [[ $TAIL -ge 0 ]]
    then
      start=$(( $count - $TAIL ))
    fi
  fi

  for (( i=$start; i < $end; i++ ))
  do 
    echo "${results[$i]}"
  done
}

function parse {
  echo "<!DOCTYPE html>" \
       "<html>" \
       "<style> body{font-family: Segoe UI, Helvetica; color: #0f0f1e; -webkit-print-color-adjust: exact;} </style>" \
       "<style> table{display: inline-block} </style>" \
       "<body>"

  filter=""
  if [ "$SPRINT" != "" ]; then
    filter="and (.list.name | test(\"Sprint $SPRINT\"))"
  fi
   
  if [ "$BACKLOG" == "YES" ]; then
    filter="$filter and (.list.name | test(\"backlog\"; \"i\"))"
  elif [ "$BACKLOG" != "NO" ]; then
    filter="$filter and (.labels[] | .name | test(\"$BACKLOG\"; \"i\"))" 
  fi
  
  if [ "$LIST" != "" ]; then
    filter="$filter and (.list.name == \"$LIST\") "
  fi

  if [ "$EVALUATED" == "N" ]; then
    filter="$filter and (.cost == \"\")"
  elif [ "$EVALUATED" == "Y" ]; then
    filter="$filter and (.cost != \"\")"
  fi

  cat $INPUT \
  | "$ROOT/extract.card.sh" "$filter" \
  | jq -r '@json "\(.[])"' \
  | export

  echo "</body>" \
       "</html>"
}

function plot {
  cat $INPUT |
    "$ROOT/extract.plot.sh" 1 |
    "$ROOT/extract.plot.sh" 2
}

OUTPUT="NO"
BACKLOG="NO"
TAIL=-1
HEAD=-1
PLOT=false
ROOT=$(dirname $(echo $0))
INPUT="$ROOT/trello.json"
DISPLAY="card"
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -b|--backlog)
        BACKLOG="YES"
      ;;
      -B)
        BACKLOG="$2"
        shift
      ;;
      -d|--display)
        DISPLAY="$2"
        shift
      ;;
      -e|--evaluated)
        EVALUATED="$2"
        shift
      ;;
      -h|--head)
        HEAD=$2
        shift
      ;;
      -i|--input)
        INPUT="$2";
        shift
      ;;
      -l|--list)
        LIST=$2
        shift
      ;;
      -o|--output)
        OUTPUT="$2"
        shift
      ;;
      -p|--plot)
        PLOT=true
        shift
      ;;
      -r|--refresh)
        REFRESH="YES"
      ;;
      -s|--sprint)
        SPRINT="$2"
        shift
      ;;
      -t|--tail)
        TAIL=$2
        shift
      ;;

      *)
      ;;
  esac
  shift
done

if [ "$REFRESH" == "YES" ]; then
  curl -o $INPUT https://trello.com/b/IghukAoD.json
fi

if ( $PLOT ); then
  plot
elif [ "$OUTPUT" == "NO" ]; then
  parse
else
  parse > $OUTPUT
fi

