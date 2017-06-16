#/!bin/bash

jq "
    {} as \$idx |
    .lists as \$l |
    .cards as \$c |
 
    [
      \$c[] | 
      
      (.name | split(\" | \")) as \$n |
      
      {
        name: \$n[0],
        cost: (if \$n[1] == null then \"\" else \$n[1] end),
        list:
        (
          .idList as \$i |
          \$l[] | select ( .id == \$i )
        ) |
        {
          name: .name,
          closed: .closed
        },
        labels:
        [
          .labels[] | 
          {
            name: .name, 
            color: (if .color == \"sky\" then \"cyan\" else .color end)
          }
        ],
        desc: .desc, 
        closed: .closed
      } |
      select(.closed == false $1)
    ]"