#!/usr/bin/env bash


# Credentials checker in ansible inventory .ini files for ansible CI
# (warn and fails on forgotten credentials and/or passwords find)

# This Source Code Form is subject to the terms of the MIT License. If a copy of the MPL was not distributed with
# this file, You can obtain one at: https://github.com/alexanderbazhenoff/ansible-development-template/blob/main/LICENSE


# path to exclude from inventory files found
INVENTORY_PATH_EXCLUDE="./inventories"


INVENTORY_FILES_LIST=$(grep -iEr '^\[[_a-z-]*\:vars\]' | cut -f1 -d":" | grep -v $INVENTORY_PATH_EXCLUDE; echo "")
printf '=%.0s' {1..120}
printf "\nAnalyzing ansible inventory .ini files: \n\n%s\n\n" "$INVENTORY_FILES_LIST"

for FILENAME in $INVENTORY_FILES_LIST; do
  (grep -iEr '^ansible\_(ssh_user|ssh_pass|become_pass)\=.+' "$FILENAME" | sed 's/=.*/\=*/g' | \
    sed "s|^|$FILENAME:|") >> violations.txt
done
VIOLATIONS=$(cat violations.txt)
rm -f violations.txt
printf '=%.0s' {1..120}

if [[ -z "$VIOLATIONS" ]]; then
  printf "\nNo inventories violations found.\n"
else
  VIOLATIONS_LINES=$(echo "$VIOLATIONS" | wc -l)
  printf "\nFound %s inventories violations:\n\n%s\n" "$VIOLATIONS_LINES" "$VIOLATIONS"
  exit 1
fi