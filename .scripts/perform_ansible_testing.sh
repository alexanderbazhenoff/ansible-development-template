#!/usr/bin/env bash


# Perform ansible testing or collection(s) version(s) (semantic) increment for ansible CI
# or put your .skip_molecule_default or .skip_molecule_kvm into role directory to skip molecule role testing.

# Copyright (c) 2022 Aleksandr Bazhenov

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


print_usage_help() {
  echo "Error: unrecognized option(s): $POSITIONAL"
  echo ""
  echo "Usage:"
  echo ""
  echo "   -m | --test-mode [ansible-test-sanity|molecule-default|molecule-kvm|increment-version]"
  echo "          Run 'ansible-test sanity' or molecule for selection."
  echo "   -s | --selection [all|diff]"
  echo "          Selection for current test run: all the project or just git diff."
  echo "   -r | --requirements [yes|no]"
  echo "          Install additional pip requirements for the role (affects only for molecule testing)."
  echo "   -v | --version [minor|major|release]"
  echo "          Semantic version level to change (affects only for version increment)."
  echo "   -d | --destination-branch"
  echo "          Destination gitlab branch to take semantic version from (affects only for version increment)."
  echo "   -c | --current-branch"
  echo "          Current branch to change version and add collection tag (affects only for version increment)."
  exit 1
}

fatal_error() {
  echo "Error. $1"
  exit 1
}

remove_logs() {
  if [[ -f "collections_list" ]]; then
    echo "Clean-up previous 'collections_list' file from $(pwd) directory..."
    rm -f collections_list
  fi
  if [[ -f "roles_list" ]]; then
    echo "Clean-up previous 'roles_list' file from $(pwd) directory..."
    rm -f roles_list
  fi
  if [[ -f "overall_results" ]]; then
    echo "Clean-up previous 'overall_results' file from $(pwd) directory..."
    rm -f overall_results
  fi
}

remove_sanity_log() {
  if [[ -f "sanity_log" ]]; then
    echo "Clean-up previous 'sanity_log' file from $(pwd) directory..."
    rm -f sanity_log
  fi
}

# get ansible collections list in the project
get_collections_list() {
  DIR=$(pwd)
  echo "Getting collections_list from $(pwd) directory..."
  cd ansible_collections 2> /dev/null || fatal_error "No ansible_collections directory found."
  # shellcheck disable=SC2035
  NAMESPACES_LIST=$(ls -d */ 2> /dev/null) && \
    for NAMESPACE_ITEM in $NAMESPACES_LIST; do
      if [[ -d "${NAMESPACE_ITEM%%/}" ]]; then
        cd "$NAMESPACE_ITEM" || true
        # shellcheck disable=SC2035
        CURRENT_COLLECTIONS=$(ls -d */ 2> /dev/null) && \
          for COLLECTION_ITEM in $CURRENT_COLLECTIONS; do
            echo "ansible_collections/$NAMESPACE_ITEM${COLLECTION_ITEM%%/}" >> "$DIR"/collections_list || \
              fatal_error "Unable to write $(pwd) folder."
          done
      else
        fatal_error "Unable to get into $(pwd)$NAMESPACE_ITEM directory."
      fi
      cd ..
    done
}

get_roles_list() {
  DIR=$(pwd)
  printf "Extracting roles_list has been started in %s directory. Scanning collections items:\n%s\n" "$DIR" \
    "$COLLECTION_ITEM"
  while read -r COLLECTION_ITEM; do
    cd "$COLLECTION_ITEM" || fatal_error "Unable to get into $(pwd)/$COLLECTION_ITEM directory."
    if [[ -d "roles" ]]; then
      cd "roles" 2> /dev/null || fatal_error "Unable to get into $(pwd)/roles directory."
      # shellcheck disable=SC2035
      COLLECTION_ROLES_LIST=$(ls -d */ 2> /dev/null) && \
        while read -r ROLES_ITEM; do
          echo "$COLLECTION_ITEM/roles/$ROLES_ITEM" >> "$DIR"/roles_list
        done <<< "$COLLECTION_ROLES_LIST"
    else
      echo "There is no roles in $(pwd), skipping this path for role testing."
    fi
    cd "$DIR" || true
  done <<< "$COLLECTIONS_LIST"
}

print_performing_action_info() {
  if [[ $TEST_MODE == "ansible-test-sanity" ]] || [[ $TEST_MODE == "increment-version" ]]; then
    # shellcheck disable=SC2030
    printf "Performing %s (selection: '%s') for %s collection(s): \n\n%s\n%s\n" "${TEST_MODE//-/ }" "$SELECTION" \
      "$COLLECTIONS_LIST_LINES" "$COLLECTIONS_LIST" \
      "$([[ -n "$DIFF_MESSAGE" ]] && printf "\n according to current changes:\n\n%s\n\n" "$DIFF_MESSAGE")"
  fi
  if [[ $TEST_MODE =~ molecule- ]]; then
    # shellcheck disable=SC2031
    printf "Performing ansible molecule testing (selection: '%s', scenario: %s) for %s role(s): \n\n%s\n%s\n" \
      "$SELECTION" "${TEST_MODE#molecule-}" "$ROLES_LIST_LINES" "$ROLES_LIST" \
      "$([[ -n "$DIFF_MESSAGE" ]] && printf "\n according to current changes:\n\n%s\n\n" "$DIFF_MESSAGE")"
  fi
  printf "=%.0s" {1..120}
  printf '\n'
}

increment_version() {
  IFS='.' read -ra ver <<< "$1"
  [[ "${#ver[@]}" -ne 3 ]] && echo "Invalid semantic version string." && return 1
  if [[ "$#" -eq 1 ]]; then
    local LEVEL="release"
  else
    local LEVEL=$2
  fi

  local RELEASE=${ver[2]}
  local MINOR=${ver[1]}
  local MAJOR=${ver[0]}

  case $LEVEL in
    release)
      RELEASE=$((RELEASE+1))
    ;;
    minor)
      RELEASE=0
      MINOR=$((MINOR+1))
    ;;
    major)
      RELEASE=0
      MINOR=0
      MAJOR=$((MAJOR+1))
    ;;
    *)
      echo "Invalid level passed."
      return 2
  esac
  echo "$MAJOR.$MINOR.$RELEASE"
}


# entry point
TEST_MODE="molecule-default"
SELECTION="all"
CHANGE_VERSION_LEVEL="release"
DESTINATION_BRANCH="master"
CURRENT_BRANCH="devel"
ANY_ERR=false

PAD=$(printf '%0.1s' "."{1..60})
START_ALL=$(date +%s)

while [[ $# -gt 0 ]]; do
  KEY="$1"

  case $KEY in
  -m | --test-mode )
    TEST_MODE="$2"
    shift
    shift
    ;;
  -s | --selection )
    SELECTION="$2"
    shift
    shift
    ;;
  -r | --requirements )
    ADDITIONAL_PIP_REQUIEREMENTS="$2"
    shift
    shift
    ;;
  -v | --version )
    CHANGE_VERSION_LEVEL="$2"
    shift
    shift
    ;;
  -d | --destination-branch )
    DESTINATION_BRANCH="$2"
    shift
    shift
    ;;
  -c | --current-branch )
    CURRENT_BRANCH="$2"
    shift
    shift
    ;;
  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done

# error handling

if [[ $CHANGE_VERSION_LEVEL != "release" ]] && [[ $CHANGE_VERSION_LEVEL != "minor" ]] && \
  [[ $CHANGE_VERSION_LEVEL != "major" ]]; then
    POSITIONAL+=("$CHANGE_VERSION_LEVEL")
fi

if [[ $TEST_MODE != "ansible-test-sanity" ]] && [[ $TEST_MODE != "molecule-default" ]] && \
  [[ $TEST_MODE != "molecule-kvm" ]] && [[ $TEST_MODE != "increment-version" ]]; then
    POSITIONAL+=("$TEST_MODE")
fi

if [[ $SELECTION != "all" ]] && [[ $SELECTION != "diff" ]]; then
  POSITIONAL+=("$SELECTION")
fi

if [[ $ADDITIONAL_PIP_REQUIEREMENTS != "yes" ]] && [[ $ADDITIONAL_PIP_REQUIEREMENTS != "no" ]]; then
  POSITIONAL+=("$ADDITIONAL_PIP_REQUIEREMENTS")
fi

for VALUE in "${POSITIONAL[@]}"
do
  echo "$VALUE"
  if [[ -n $VALUE ]]; then
    print_usage_help
  fi
done

# start testing
DIR=$(pwd)
remove_logs

DIFF_MESSAGE=""
COLLECTIONS_LIST=""
get_collections_list
cd "$DIR" || fatal_error "Unable to get into $DIR directory."
COLLECTIONS_LIST=$(sed 's/ *$//g' < collections_list) || \
  fatal_error "There is no 'collections_list' file in $(pwd) directory."

ROLES_LIST=""
if [[ $TEST_MODE =~ molecule- ]]; then
  get_roles_list
  cd "$DIR" || fatal_error "Unable to get into $DIR directory."
  ROLES_LIST=$(cat roles_list) || fatal_error "There is no 'roles_list' file in $(pwd) directory."
fi

# getting collections diff
if [[ $SELECTION == "diff" ]]; then

  GIT_DIFF=$(git diff --name-only "$CI_COMMIT_BEFORE_SHA" "$CI_COMMIT_SHA")
  COLLECTIONS_DIFF_UNIQUE=$(echo "$GIT_DIFF" | awk -F "/" '{print $1 "/" $2 "/" $3}' | sort -u || echo "")
  COLLECTIONS_LIST=$(grep "$COLLECTIONS_DIFF_UNIQUE" collections_list)
  DIFF_MESSAGE+="$GIT_DIFF"

  # getting roles diff for molecule testing
  if [[ $TEST_MODE =~ molecule- ]]; then
    ROLES_DIFF_UNIQUE=$(echo "$GIT_DIFF" | grep "/roles/" | awk -F "/" '{print $1 "/" $2 "/" $3 "/" $4 "/" $5}' | \
      sort -u || echo "")
    if [[ -n $ROLES_DIFF_UNIQUE ]]; then
      echo "$ROLES_LIST" > roles_list
      ROLES_LIST=$(grep "$ROLES_DIFF_UNIQUE" roles_list) || fatal_error "Unable to read 'roles_list' file."
    else
      ROLES_LIST=""
    fi
  fi

fi

# start ansible-test sanity / collection(s) version increment
if [[ $TEST_MODE == "ansible-test-sanity" ]] || [[ $TEST_MODE == "increment-version" ]]; then
  if [[ -n $COLLECTIONS_LIST ]]; then
    COLLECTIONS_LIST_LINES=$(echo "$COLLECTIONS_LIST" | wc -l)
    print_performing_action_info

    for CHECK_ITEM in $COLLECTIONS_LIST; do
      DIR=$(pwd)
      cd "$CHECK_ITEM" || fatal_error "Something went wrong, unable to get into $CHECK_ITEM directory"
      CHECK_ITEM_SHORT="${CHECK_ITEM##ansible_collections\/}"
      printf "\n\nPerforming %s of %s\n" "${TEST_MODE//-/ }" "${CHECK_ITEM_SHORT//\//.}..."
      START=$(date +%s)

      if [[ $TEST_MODE == "ansible-test-sanity" ]]; then
        # ansible-test sanity
        remove_sanity_log
        ansible-test sanity --docker 2> >(tee sanity_log >&2) && TEST_RESULTS="PASS" || TEST_RESULTS="FAIL"
        ANSIBLE_SANITY_ERRORS="$(cat sanity_log)"
        if [[ -n "$ANSIBLE_SANITY_ERRORS" ]]; then
          printf "=%.0s" {1..120}
          printf "\nThere was a violations/warnings:\n\n%s\n\n" "$ANSIBLE_SANITY_ERRORS"
          TEST_RESULTS="FAIL"
        fi
        remove_sanity_log
      else
        # collection(s) version increment
        git checkout "$DESTINATION_BRANCH" || TEST_RESULTS="FAIL"
        CURRENT_COLLECTION_VERSION=$(grep "version: " galaxy.yml | awk '{print $2}') || TEST_RESULTS="FAIL"
        printf "Current %s collection version is %s.\n" "${CHECK_ITEM_SHORT//\//.}" "$CURRENT_COLLECTION_VERSION"
        NEW_COLLECTION_VERSION=$(increment_version "$CURRENT_COLLECTION_VERSION" "$CHANGE_VERSION_LEVEL") || \
          TEST_RESULTS="FAIL"
        printf "According to '%s' change level new version is: %s\n" "$CHANGE_VERSION_LEVEL" "$NEW_COLLECTION_VERSION"
        git checkout "$CURRENT_BRANCH" || TEST_RESULTS="FAIL"
        git pull || TEST_RESULTS="FAIL"
        if [[ $TEST_RESULTS != "FAIL" ]] && [[ -n "$CURRENT_COLLECTION_VERSION" ]]; then
          sed -i -e "s/.*$CURRENT_COLLECTION_VERSION.*/version: $NEW_COLLECTION_VERSION/g" galaxy.yml && \
            TEST_RESULTS="PASS" || TEST_RESULTS="FAIL"
          git add galaxy.yml || TEST_RESULTS="FAIL"
          git commit -m "${CHECK_ITEM_SHORT//\//.} automated version increment"
          git tag -a "${CHECK_ITEM_SHORT//\//.}-$NEW_COLLECTION_VERSION" "$(git log -n 1 --pretty=format:%H)" -m \
            "${CHECK_ITEM_SHORT//\//.}-$NEW_COLLECTION_VERSION automated version increment" || TEST_RESULTS="FAIL"
          if [[ -n "$GITLAB_TOKEN" ]] && [[ -n "$CI_PROJECT_NAMESPACE" ]] && [[ -n "$CI_PROJECT_NAME" ]]; then
            git remote set-url origin \
              "http://oauth2:${GITLAB_TOKEN}@gitlab.emzior/${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}.git"
            git remote -v
          fi
          git push origin "${CHECK_ITEM_SHORT//\//.}-$NEW_COLLECTION_VERSION" -o ci.skip || TEST_RESULTS="FAIL"
          git merge "${CHECK_ITEM_SHORT//\//.}-$NEW_COLLECTION_VERSION" || TEST_RESULTS="FAIL"
          git push origin "$CURRENT_BRANCH" -o ci.skip || TEST_RESULTS="FAIL"
        else
          printf "Unable to change version for %s." "$CHECK_ITEM"
          TEST_RESULTS="FAIL"
        fi
      fi

      END=$(date +%s)
      [[ $TEST_RESULTS == "FAIL" ]] && ANY_ERR=true
      RUNTIME_HMS="$(((END-START) / 3600))h:$((((END-START) / 60) % 60))m:$(((END-START) % 60))s"
      printf "=%.0s" {1..120}
      printf '\n'
      cd "$DIR" || fatal_error "Something went wrong, unable to get into $DIR directory."
      ITEM_PRINTABLE="${CHECK_ITEM_SHORT//\//.}"
      ITEM_PAD="$ITEM_PRINTABLE$(printf '%*.*s' 0 $((60 - ${#ITEM_PRINTABLE} - ${#RUNTIME_HMS} )) "$PAD")$RUNTIME_HMS"
      echo "$ITEM_PAD | $TEST_RESULTS" >> overall_results
    done
  else
    printf "=%.0s" {1..120}
    printf '\n'
    echo "Nothing to test."
  fi

fi

# start molecule testing
if [[ $TEST_MODE =~ molecule- ]]; then
  if [[ -n $ROLES_LIST ]]; then
    ROLES_LIST_LINES=$(echo "$ROLES_LIST" | wc -l)
    print_performing_action_info

    for CHECK_ITEM in $ROLES_LIST; do
      DIR=$(pwd)
      cd "$CHECK_ITEM" || fatal_error "Something went wrong, unable to get in $CHECK_ITEM directory."
      FULL_ROLE_NAME=$(echo "${CHECK_ITEM#ansible_collections\/}" | sed 's/.roles//' | sed 's/\//./g' | sed 's/.$//')

      if [[ -d "molecule/${TEST_MODE/*-/}" ]] && [[ ! -f ".skip_${TEST_MODE//-/_}" ]]; then

        START=$(date +%s)
        echo "Testing $FULL_ROLE_NAME with '${TEST_MODE/*-/}' scenario..."
        if [[ -f "requirements.txt" ]] && [[ $ADDITIONAL_PIP_REQUIEREMENTS == "yes" ]]; then
          printf "Setting up pip requirements:\n%s\n" "$(cat 'requirements.txt')"
          python3 -m pip install -r requirements.txt
          printf "=%.0s" {1..120}
          printf '\n'
        else
          printf "ADDITIONAL_PIP_REQUIEREMENTS='%s' or no 'requirements.txt' in %s role directory. %s\n" \
            "$ADDITIONAL_PIP_REQUIEREMENTS" "$(pwd)" "Skipping additional pip requirements install."
          printf "=%.0s" {1..120}
          printf '\n'
        fi
        molecule test -s "${TEST_MODE/*-/}" && TEST_RESULTS="PASS" || TEST_RESULTS="FAIL"
        END=$(date +%s)
        RUNTIME_HMS="$(((END-START) / 3600))h:$((((END-START) / 60) % 60))m:$(((END-START) % 60))s"

      else

        RUNTIME_HMS="0h:00m:00s"
        if [[ ! -f ".skip_${TEST_MODE//-/_}" ]]; then
          if [[ "${TEST_MODE/*-/}" == "kvm" ]]; then
            printf "Skipping test of %s with '%s' scenario: 'molecule/%s' directory not found. %s\n" \
              "$FULL_ROLE_NAME" "${TEST_MODE/*-/}" "${TEST_MODE/*-/}" \
              "It's ok for kvm molecule testing scenario because this is an optional."
            TEST_RESULTS="SKIP"
          else
            printf "Molecule testing of %s with '%s' scenario exited with FAIL state: 'molecule/%s' %s %s %s\n" \
              "$FULL_ROLE_NAME" "${TEST_MODE/*-/}" "${TEST_MODE/*-/}" "directory not found." \
              "It's not ok for default molecule testing scenario because this is strongly required" \
              "or use '.skip_molecule_default' file in ansible role folder instead."
            TEST_RESULTS="FAIL"
          fi
        else
          printf "File %s exists, skipping %s scenario for %s.\n" ".skip_${TEST_MODE//-/_}" "${TEST_MODE//-/_}" \
            "$FULL_ROLE_NAME"
          TEST_RESULTS="SKIP"
        fi
        printf '=%.0s' {1..120}
        printf '\n'

      fi

      [[ $TEST_RESULTS == "FAIL" ]] && ANY_ERR=true
      cd "$DIR" || fatal_error "Something went wrong, unable to get into $DIR directory."
      ITEM_PAD="$FULL_ROLE_NAME$(printf '%*.*s' 0 $((60 - ${#FULL_ROLE_NAME} - ${#RUNTIME_HMS} )) "$PAD")$RUNTIME_HMS"
      RUNTIME_HMS_PAD="$(printf '%*.*s' 0 $((12 - ${#RUNTIME_HMS_PAD} )) "...")$RUNTIME_HMS"
      echo "$ITEM_PAD | $TEST_RESULTS" >> overall_results
    done
  else
    printf "=%.0s" {1..120}
    printf '\n'
    echo "Nothing to test."
  fi
fi

if [[ -f overall_results ]]; then
  printf "\n\nOverall:\n\n%s\n" "$(cat overall_results)"
  END_ALL=$(date +%s)
  RUNTIME_HMS="$(((END_ALL-START_ALL) / 3600))h:$((((END_ALL-START_ALL) / 60) % 60))m:$(((END_ALL-START_ALL) % 60))s"
  printf "\nTotal: %s\n\n" "$RUNTIME_HMS"
fi
printf '=%.0s' {1..120}
printf '\n'

remove_logs

# check if any error
if $ANY_ERR; then
  exit 1
fi
