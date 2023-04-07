#!/usr/bin/env bash


# Credentials checker in ansible inventory .ini files for ansible CI
# (warn and fails on forgotten credentials and/or passwords find)

# Copyright (c) 2022-2023 Alexander Bazhenov

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


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