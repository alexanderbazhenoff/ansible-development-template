#!/usr/bin/env bash


# Linter and check results script for ansible-lint CI.
# Usage: './ansible_lint.sh [lint mode]' (where: lint mode=all|diff)


# Copyright (c) 2022-2023 Aleksandr Bazhenov

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


double_splitter() {
  printf '=%.0s' {1..120}
  printf '\n'
}

LINT_MODE=$1
ANY_ERR=false
double_splitter
printf "Current lint mode: \e[1;36m%s\e[0m\n \n" "$LINT_MODE"
ansible --version || exit 1
ansible-lint --version || exit 1

printf "\e[37mStarting ansible-lint...\e[0m\n"
ansible-lint --force-color -p | grep -v "Found roles" | grep -v "Found playbooks" | grep -v "Examining " | \
  grep -vE "Unknown file type: roles\/.+\/tasks\/main.yml" | sed 's/ *$//g' > lint-results.txt || ANY_ERR=true
LINT_RESULTS=$(cat lint-results.txt)

if [[ $LINT_MODE == "diff" ]]; then
  printf "\e[37mCounting diff of ansible-lint results fot current commit, grep ansible-lint results by diff...\e[0m\n"
  GIT_DIFF=$(git diff --name-only "$CI_COMMIT_BEFORE_SHA" "$CI_COMMIT_SHA" || echo "")
  if [[ -n "$GIT_DIFF" ]]; then
    GIT_DIFF_FILES=$(echo "$GIT_DIFF" | wc -l)
    LINT_RESULTS=$(grep "$GIT_DIFF" lint-results.txt)
    double_splitter
    printf "Current commit changes (\e[37m%s\e[0m files):\n \n\e[32m%s\e[0m \n \n" "$GIT_DIFF_FILES" "$GIT_DIFF"
  fi
fi

LINT_RESULTS_LINES=$(echo "$LINT_RESULTS" | wc -l)
double_splitter
if [[ -z "$LINT_RESULTS" ]] && ! $ANY_ERR; then
  printf "No ansible-lint violation(s) and/or warning(s) found (\e[1;36m%s\e[0m).\n" "$LINT_MODE"
else
  printf "Found: \e[31m%s\e[0m ansible-lint violation(s) (\e[1;36m%s\e[0m):\n \n%s\n" "$LINT_RESULTS_LINES" \
    "$LINT_MODE" "$LINT_RESULTS"
  ANY_ERR=true
fi

# check if any error
if $ANY_ERR; then
  exit 1
fi
