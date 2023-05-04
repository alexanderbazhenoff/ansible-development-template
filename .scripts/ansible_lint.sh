#!/usr/bin/env bash


# Linter and check results script for ansible-lint CI
#
# Usage: './ansible_lint.sh [lint mode]' (where: lint mode=all|diff)

# Copyright (c) 2022 Aleksandr Bazhenov

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


LINT_MODE=$1
ANY_ERR=false
printf '=%.0s' {1..120}
printf "\nCurrent lint mode: %s\n\n" "$LINT_MODE"
ansible --version || exit 1
ansible-lint --version || exit 1

echo "Starting ansible-lint..."
# Grep can be modified depending on possible output change during future ansible-lint updates. Be careful!
ansible-lint -p | grep -v "Found roles" | grep -v "Found playbooks" | grep -v "Examining " | \
  grep -vE "Unknown file type: roles\/.+\/tasks\/main.yml" | sed 's/ *$//g' > lint-results.txt || ANY_ERR=true
LINT_RESULTS=$(cat lint-results.txt)

if [[ $LINT_MODE == "diff" ]]; then
  echo "Counting diff of ansible-lint results fot current commit, grep ansible-lint results by diff, etc..."
  GIT_DIFF=$(git diff --name-only "$CI_COMMIT_BEFORE_SHA" "$CI_COMMIT_SHA" || echo "")
  if [[ -n "$GIT_DIFF" ]]; then
    GIT_DIFF_FILES=$(echo "$GIT_DIFF" | wc -l)
    LINT_RESULTS=$(grep "$GIT_DIFF" lint-results.txt)
    printf '=%.0s' {1..120}
    printf "\nCurrent commit changes (%s files):\n\n%s \n\n" "$GIT_DIFF_FILES" "$GIT_DIFF"
  fi
fi

LINT_RESULTS_LINES=$(echo "$LINT_RESULTS" | wc -l)
printf '=%.0s' {1..120}
if [[ -z "$LINT_RESULTS" ]] && ! $ANY_ERR; then
  printf "\nNo ansible-lint violations and/or warnings found (%s).\n" "$LINT_MODE"
else
  printf "\nFound: %s ansible-lint violations (%s):\n\n%s\n" "$LINT_MODE" "$LINT_RESULTS_LINES" "$LINT_RESULTS"
  ANY_ERR=true
fi

# check if any error
if $ANY_ERR; then
  exit 1
fi
