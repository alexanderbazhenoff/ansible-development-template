#!/usr/bin/env bash


# Perform ansible testing for CI: ansible sanity testing, ansible molecule testing and increment version.


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
  printf "\n \n%sError:%s $1\n \n" "${ESC}[31m" "${ESC}[0m"
  exit 1
}

double_splitter() {
  printf '=%.0s' {1..120}
  printf '\n'
}

remove_logs() {
  find . -maxdepth 1 -type f -name "collections_list_$START_ALL" -or -name "roles_list_$START_ALL" -or \
    -name "overall_results_$START_ALL" | xargs -0 rm -f
}

remove_sanity_log() {
  find . -maxdepth 1 -type f -name "sanity_log_$START_ALL" | xargs -0 rm -f
}

colorize_states() {
  sed "s/PASS/${ESC}[42m PASS ${ESC}[0m/g; s/FAIL/${ESC}[41m FAIL ${ESC}[0m/g; s/SKIP/${ESC}[1;43m SKIP ${ESC}[0m/g"
}

print_color_time() {
  printf "${ESC}[1;45m %s ${ESC}[0m" "$(date '+%Y.%m.%d %H:%M:%S')"
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
  local GREEN="${ESC}[32m"
  local L_BLUE="${ESC}[1;36m"
  local BLUE="${ESC}[36m"
  local NO_COL="${ESC}[0m"
  local AC_MSG="according to current changes"
  if [[ $TEST_MODE == "ansible-test-sanity" ]] || [[ $TEST_MODE == "increment-version" ]]; then
    # shellcheck disable=SC2030
    printf "\n \nPerforming %s (selection: '%s') for %s collection(s):\n%s\n%s\n" \
      "${L_BLUE}${TEST_MODE//-/ }${NO_COL}" \
      "${L_BLUE}${SELECTION}${NO_COL}" \
      "${L_BLUE}${COLLECTIONS_LIST_LINES}${NO_COL}" \
      "${BLUE}$(get_printable_role_collection "$COLLECTIONS_LIST")${NO_COL}" \
      "$([[ -n "$DIFF_MESSAGE" ]] && printf "\n%s:\n%s%s%s\n \n" "$AC_MSG" "$GREEN" "$DIFF_MESSAGE" "$NO_COL")"
  fi
  if [[ $TEST_MODE =~ molecule- ]]; then
    # shellcheck disable=SC2031
    printf "\n \nPerforming ansible molecule testing (selection: '%s', scenario: '%s') for %s role(s):\n%s\n%s\n" \
      "${L_BLUE}${SELECTION}${NO_COL}" \
      "${L_BLUE}${TEST_MODE#molecule-}${NO_COL}" \
      "${L_BLUE}${ROLES_LIST_LINES}${NO_COL}" \
      "${BLUE}$(get_printable_role_collection "$ROLES_LIST")${NO_COL}" \
      "$([[ -n "$DIFF_MESSAGE" ]] && printf "\n%s:\n%s%s%s\n \n" "$AC_MSG" "$GREEN" "$DIFF_MESSAGE" "$NO_COL")"
  fi
  double_splitter
}

git_switch_current_branch() {
  (
    git checkout "$CURRENT_BRANCH"
    git pull
  ) || fatal_error "Unable to checkout '$CURRENT_BRANCH' branch as a current. Make sure branch name is correct."
}

git_add_tag() {
  git tag -a "$ITEM_PRINTABLE-$NEW_COLLECTION_VERSION" "$(git log -n 1 --pretty=format:%H)" -m \
    "$ITEM_PRINTABLE-$NEW_COLLECTION_VERSION automated version increment"
}

get_ansible_collection_version() {
  grep -P "^version:\s(\d{1,}.){3}" galaxy.yml 2> /dev/null | awk '{print $2}'
}

get_printable_role_collection() {
  echo "$1" | sed "s/^ansible_collections\///; s/\/roles//; s/\/$//; s/\//./g"
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
GITLAB_URL="gitlab.tmispb"

ESC=$(printf '\033')
BLD="${ESC}[1m"
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
    ADDITIONAL_PIP_REQUIREMENTS="$2"
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
if [[ $ADDITIONAL_PIP_REQUIREMENTS != "yes" ]] && [[ $ADDITIONAL_PIP_REQUIREMENTS != "no" ]]; then
  POSITIONAL+=("$ADDITIONAL_PIP_REQUIREMENTS")
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
      ITEM_PRINTABLE=$(get_printable_role_collection "$CHECK_ITEM")
      ITEM_PRINTABLE_COLOR="${ESC}[44m $ITEM_PRINTABLE ${ESC}[0m"
      TEST_MODE_COLOR="${ESC}[36m${TEST_MODE//-/ }${ESC}[0m"
      printf "\n%s----> %s | Performing %s of %s...\n" "$BLD" "$(print_color_time)${BLD}" "${TEST_MODE_COLOR}${BLD}" \
        "$ITEM_PRINTABLE_COLOR"
      START=$(date +%s)

      if [[ $TEST_MODE == "ansible-test-sanity" ]]; then
        # ansible-test sanity
        remove_sanity_log
        ansible-test sanity --docker 2> >(tee "sanity_log_$START_ALL" >&2) && TEST_RESULTS="PASS" || TEST_RESULTS="FAIL"
        ANSIBLE_SANITY_ERRORS="$(cat "sanity_log_$START_ALL")"
        if [[ -n "$ANSIBLE_SANITY_ERRORS" ]]; then
          double_splitter
          printf "There was a${ESC}[31m violations/warnings\e[0m:\n \n%s\n \n" "$ANSIBLE_SANITY_ERRORS"
          TEST_RESULTS="FAIL"
        fi
        remove_sanity_log
      else
        # collection(s) version increment
        NO_DESTINATION_BRANCH=false
        NO_GALAXY_YML_ERR_MSG="Looks like there is no galaxy.yml file in "
        git checkout "$DESTINATION_BRANCH" || NO_DESTINATION_BRANCH=true
        CURRENT_COLLECTION_VERSION=$(get_ansible_collection_version)
        if [[ -z "$CURRENT_COLLECTION_VERSION" ]] && $NO_DESTINATION_BRANCH; then
            git_switch_current_branch
            CURRENT_COLLECTION_VERSION=$(get_ansible_collection_version)
        fi
        if [[ -n "$CURRENT_COLLECTION_VERSION" ]] && $NO_DESTINATION_BRANCH; then
          printf "%s branch. %s getting collection version from $CURRENT_BRANCH branch..." "$NO_GALAXY_YML_ERR_MSG" \
            "Is this collection and/or namespace is recently added?"
        elif [[ -z "$CURRENT_COLLECTION_VERSION" ]] && $NO_DESTINATION_BRANCH; then
          fatal_error "$NO_GALAXY_YML_ERR_MSG'$CURRENT_COLLECTION_VERSION' branch, neither from $CURRENT_BRANCH."
        fi
        printf "Current %s collection version is %s%s.\n" "$ITEM_PRINTABLE_COLOR" "$BLD" \
          "${ESC}[45m$CURRENT_COLLECTION_VERSION${ESC}[0m"
        NEW_COLLECTION_VERSION=$(increment_version "$CURRENT_COLLECTION_VERSION" "$CHANGE_VERSION_LEVEL") || \
          fatal_error "Unable to calculate new version. Please make sure semantic version was specified."
        printf "According to '%s' change level new version is: %s\n" "$CHANGE_VERSION_LEVEL" "$NEW_COLLECTION_VERSION"
        git_switch_current_branch
        (
          sed -i -e "s/.*$CURRENT_COLLECTION_VERSION.*/version: $NEW_COLLECTION_VERSION/g" galaxy.yml
          git add galaxy.yml
          git commit -m "$ITEM_PRINTABLE automated version increment"
          git_add_tag || {
            git tag -d "$ITEM_PRINTABLE-$NEW_COLLECTION_VERSION"
            git_add_tag
          }
          if [[ -n "$GITLAB_TOKEN" ]] && [[ -n "$CI_PROJECT_NAMESPACE" ]] && [[ -n "$CI_PROJECT_NAME" ]]; then
            git remote set-url origin \
              "http://oauth2:${GITLAB_TOKEN}@${GITLAB_URL}/${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}.git"
            git remote -v
          fi
          git push origin "$ITEM_PRINTABLE-$NEW_COLLECTION_VERSION" -o ci.skip
          git merge "$ITEM_PRINTABLE-$NEW_COLLECTION_VERSION"
          git push origin "$CURRENT_BRANCH" -o ci.skip
        ) && TEST_RESULTS="PASS" || TEST_RESULTS="FAIL"
        [[ $TEST_RESULTS == "FAIL" ]] && falal_error "Unable to change version for ${CHECK_ITEM}."

      fi

      END=$(date +%s)
      [[ $TEST_RESULTS == "FAIL" ]] && ANY_ERR=true
      RUNTIME_HMS="$(((END-START) / 3600))h:$((((END-START) / 60) % 60))m:$(((END-START) % 60))s"
      double_splitter
      cd "$DIR" || fatal_error "Something went wrong, unable to get into $DIR directory."
      ITEM_PAD="$ITEM_PRINTABLE$(printf '%*.*s' 0 $((60 - ${#ITEM_PRINTABLE} - ${#RUNTIME_HMS} )) "$PAD")$RUNTIME_HMS"
      echo "$ITEM_PAD | $TEST_RESULTS" >> "overall_results_$START_ALL"
      printf "\n \n%s<---- %s | %s of %s completed in %s with %s.\n \n" "$BLD" "$(print_color_time)${BLD}" \
        "${TEST_MODE_COLOR}${BLD}" "${ITEM_PRINTABLE_COLOR}${BLD}" "${RUNTIME_HMS}${BLD}" \
        "$(echo "$TEST_RESULTS" | colorize_states)"
    done
  else
    double_splitter
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
      FULL_ROLE_NAME=$(get_printable_role_collection "$CHECK_ITEM")
      FULL_ROLE_NAME_COLOR="$BLD${ESC}[44m $FULL_ROLE_NAME ${ESC}[0m"
      TEST_MODE_COLOR="${ESC}[0m'${ESC}[36m${TEST_MODE/*-/}${ESC}[0m'"

      if [[ -d "molecule/${TEST_MODE/*-/}" ]] && [[ ! -f ".skip_${TEST_MODE//-/_}" ]]; then

        START=$(date +%s)
        printf "\n%s----> %s | Testing %s with %s scenario...%s\n" "$BLD" "$(print_color_time)${BLD}" \
          "${FULL_ROLE_NAME_COLOR}${BLD}" "${TEST_MODE_COLOR}${BLD}" "${ESC}[0m"
        if [[ -f "requirements.txt" ]] && [[ $ADDITIONAL_PIP_REQUIREMENTS == "yes" ]]; then
          printf "Setting up pip requirements:\n%s\n" "$(cat 'requirements.txt')"
          python3 -m pip install -r requirements.txt
          double_splitter
        else
          printf "ADDITIONAL_PIP_REQUIREMENTS='%s' and/or there's no 'requirements.txt' in %s role directory. %s\n" \
            "$ADDITIONAL_PIP_REQUIREMENTS" "$(pwd)" "Skipping additional pip requirements install."
          double_splitter
        fi
        molecule test -s "${TEST_MODE/*-/}" && TEST_RESULTS="PASS" || TEST_RESULTS="FAIL"
        END=$(date +%s)
        RUNTIME_HMS="$(((END-START) / 3600))h:$((((END-START) / 60) % 60))m:$(((END-START) % 60))s"

      else

        RUNTIME_HMS="0h:00m:00s"
        if [[ ! -f ".skip_${TEST_MODE//-/_}" ]]; then
          NOT_FOUND_COLOR="${ESC}[31mnot found${ESC}[0m"
          if [[ "${TEST_MODE/*-/}" == "kvm" ]]; then
            printf "%s test of %s with %s scenario: 'molecule/%s' directory %s. %s\n" \
              "$BLD${ESC}[1;33mSkipping${ESC}[0m" "$FULL_ROLE_NAME_COLOR" "$TEST_MODE_COLOR" "${TEST_MODE/*-/}" \
              "$NOT_FOUND_COLOR" "It's ok for kvm molecule testing scenario because this is an optional."
            TEST_RESULTS="SKIP"
          else
            printf "%s %s with %s scenario exited with${ESC}31m FAIL${ESC}0m state: 'molecule/%s' %s %s. %s %s\n" \
              "Molecule testing of" "$FULL_ROLE_NAME_COLOR" "$TEST_MODE_COLOR" "${TEST_MODE/*-/}" "directory." \
              "$NOT_FOUND_COLOR" "It's strongly recommended for default molecule testing scenario or use" \
              "'.skip_molecule_default' file in ansible role folder instead."
            TEST_RESULTS="FAIL"
          fi
        else
          printf "File %s exists, %s %s scenario for %s.\n" ".skip_${TEST_MODE//-/_}" \
            "$BLD${ESC}[1;33mskipping${ESC}[0m" "$TEST_MODE_COLOR" "$FULL_ROLE_NAME"
          TEST_RESULTS="SKIP"
        fi

      fi

      [[ $TEST_RESULTS == "FAIL" ]] && ANY_ERR=true
      cd "$DIR" || fatal_error "Something went wrong, unable to get into $DIR directory."
      ITEM_PAD="$FULL_ROLE_NAME$(printf '%*.*s' 0 $((60 - ${#FULL_ROLE_NAME} - ${#RUNTIME_HMS} )) "$PAD")$RUNTIME_HMS"
      RUNTIME_HMS_PAD="$(printf '%*.*s' 0 $((12 - ${#RUNTIME_HMS_PAD} )) "...")$RUNTIME_HMS"
      echo "$ITEM_PAD | $TEST_RESULTS" >> "overall_results_$START_ALL"
      if [[ $TEST_RESULTS != "SKIP" ]]; then
        double_splitter
        printf "\n \n%s<---- %s | Molecule testing with %s scenario of %s completed in %s with %s.\n \n" "$BLD" \
          "$(print_color_time)${BLD}" "${TEST_MODE_COLOR}${BLD}" "${FULL_ROLE_NAME_COLOR}${BLD}" \
          "${RUNTIME_HMS}${BLD}" "$(echo "$TEST_RESULTS" | colorize_states)"
      fi
    done
  else
    double_splitter
    echo "Nothing to test."
  fi
fi

if [[ -f "overall_results_$START_ALL" ]]; then
  double_splitter
  printf "\n \n%sOverall:%s\n \n%s\n" "$BLD" "${ESC}[0m" "$(< "overall_results_$START_ALL" colorize_states || true)"
  END_ALL=$(date +%s)
  RUNTIME_HMS="$(((END_ALL-START_ALL) / 3600))h:$((((END_ALL-START_ALL) / 60) % 60))m:$(((END_ALL-START_ALL) % 60))s"
  printf "\n \n%sTotal%s: %s\n \n" "$BLD" "${ESC}[0m" "$RUNTIME_HMS"
fi
double_splitter
remove_logs
if $ANY_ERR; then
  exit 1
fi
