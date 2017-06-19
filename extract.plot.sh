#/!bin/bash

case $1 in
  1)
    jq "([
          .labels[] |
          select(.name | test(\"Sprint\"; \"ix\") | not)
        ] +
        [
          {
            \"id\": 0,
            \"name\": \"Total\"
          }
        ]) as \$labels |
    
        .cards as \$cards |
        
        [
          .lists[] |
          select(.name | test(\"Sprint\")) |
          (.name | match(\"[a-zA-Z]+.([a-zA-Z]+)..S([0-9]+).([0-9]+)\"; \"x\")) as \$sprint |
          (\$sprint.captures[1].string | tonumber) as \$sprintStart |
          (\$sprint.captures[2].string | tonumber) as \$sprintEnd |
            {
              \"sprint\": \$sprint.captures[0].string,
              \"start\": \$sprintStart,
              \"end\": \$sprintEnd,
              \"duration\": (\$sprintEnd - \$sprintStart + 1),
              \"projects\": 
              [
                .id as \$sprintId |
                \$labels[] |
                {
                  \"name\": .name,
                  \"id\": .id,
                  \"cost\": 
                    (
                      .id as \$labelId |
                      [
                        \$cards[] | 
                        select(
                          .idList == \$sprintId and 
                          .closed == false and
                          (
                            \$labelId == 0 or
                            (.labels[] | (.id == \$labelId))
                          )
                        ) |
                        .name |
                        split(\" | \")[1]|
                        tonumber
                      ] | add
                    )
                } |
                select(.cost != null)
              ]
            }
          ] | reverse"
  ;;
  2)
    jq -r '
        (
          [
            "Project",
            (
              [
                .[] |
                .projects[] |
                [
                  .name,
                  .id
                ]
              ] |
              unique |
              .[][0]
            )
          ] | 
          @tsv
        ),
    
        (
          .[] as $s |
          [
            $s.sprint,
            [
              [
                .[] |
                .projects[] |
                [
                  .name,
                  .id
                ]
              ] |
              unique |
              .[][1]
            ]
            [] as $id |
            
            $s.projects |
            if contains([{"id": $id}])
            then
              .[] | select(.id == $id).cost
            else
              "-"
            end
          ] |
          @tsv
        )
      '
  ;;
esac
