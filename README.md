# trello-scrum

## Requires:
- jq 1.5

## Tested on:
- bash 4.3.11

## Usage:
- --backlog / -b        : Only cards from backlog
- -B <project>          : Only cards from <project>
- --evaluated / -e <Y/N>: Only cards evaluated (Y) or not (N)
- --list / -l <list>    : Only cards in trello list <list>
- --sprint / -s <sprint>: Only cards from sprint <sprint>

- --output / -o <file>  : Define output file <file> (stdout if not defined)
- --input / -i <file>   : Define input file <file> (trello.json if not defined)
- --display / -d <name> : Select <name> template (card if not defined)
- --head / -h <n>       : Only generate the <n> first cards
- --tail / -t <n>       : Only generate the <n> last cards

- --refresh / -r        : Force Trello refresh. NOT WORKING,
                          'trello.json' must be placed manually

