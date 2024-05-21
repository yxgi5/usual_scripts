#!/bin/bash

# BASH Shell: For Loop File Names With Spaces
# Set $IFS variable
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for files in `find -name '*.desktop'`; do echo $files | sed 's/$/"/' | sed 's/^/"/' | xargs perl -pi -e 's|^(.*)?\/dosdevices\/.\:\/home\/andy\/\.wine_x86(.*)$|$1$2|g' ; done
for files in `find -name '*.desktop'`; do echo $files | sed 's/$/"/' | sed 's/^/"/' | xargs perl -pi -e 's|^Exec\=env\ WINEPREFIX\=(.*)$|Exec\=env\ LANG=zh\_CN.UTF\-8\ WINEPREFIX\=$1|' ; done

# restore $IFS
IFS=$SAVEIFS
