#!/bin/bash

function export {
  declare -A index
  results=()
  i=0
  while read input
  do 
      
      name=$(echo $input | jq -r '@html "\(.name)"' | sed -e 's/\([\\^*+.$-\\/&]\)/\\\1/g')
      desc=$(echo $input | jq -r '@html "\(.desc)"' | sed -e 's/\([\\^*+.$-\\/&]\)/\\\1/g')
      cost=$(echo $input | jq -r '@html "\(.cost)"' | sed -e 's/\([\\^*+.$-\\/&]\)/\\\1/g')
      color=$(echo $input | jq -r '@html "\([.labels[] | select(.name | test("sprint"; "i") | not)] | first(.[]).color)"' | sed -e 's/\([\\^*+.$-\\/&]\)/\\\1/g')
      
      ((index[$color]=index[$color]+1))
       
      results[$i]=$(sed -e "s/###CardTitle###/$name/" \
                        -e "s/###CardDesc###/$desc/" \
                        -e "s/###CardValue###/$cost/" \
                        -e "s/###CardColor###/$color/" \
                        -e "s/###CardCount###/#${index[$color]}/" \
                        template.html)
      ((i=i+1))
  done

  if [[ $HEAD -ge 0 ]]
  then
    if [[ $TAIL -ge 0 ]]
    then
      res=${results[@]:$(( $HEAD - $TAIL )):$TAIL}
    else
      res=${results[@]:0:$HEAD}
    fi
  else
    if [[ $TAIL -ge 0 ]]
    then
      res=${results[@]:$(( ${#resuls[*]} - $TAIL ))}
    else
      res=${results[@]}
    fi
  fi

  for result in $res
  do
    echo $result
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

  echo $filter >&2

  cat trello.json \
  | jq "{} as \$idx | .lists as \$l | .cards as \$c | [ \$c[] | (.name | split(\" | \")) as \$n | { name: \$n[0], cost: (if \$n[1] == null then \"\" else \$n[1] end), list: (.idList as \$i | \$l[] | select ( .id == \$i )) | {name: .name, closed: .closed}, labels: [ .labels[] | { name: .name, color: (if .color == \"sky\" then \"cyan\" else .color end)} ], desc: .desc, closed: .closed} | select(.closed == false $filter) ]" \
  | jq -r '@json "\(.[])"' \
  | export

  echo "</body>" \
       "</html>"
}

OUTPUT="NO"
BACKLOG="NO"
TAIL=-1
HEAD=-1
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
      -e|--evaluated)
        EVALUATED="$2"
        shift
      ;;
      -h|--head)
        HEAD=$2
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
  curl -o trello.json https://trello.com/b/IghukAoD.json
fi

if [ "$OUTPUT" == "NO" ]; then
  parse
else
  parse > $OUTPUT
fi

