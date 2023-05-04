#!/usr/bin/env bash


### Installs ansible pip and ansible_molecule testing dependencies

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


TEST_SCENARIO="default"
KVM_IMAGES_PATH="/var/lib/libvirt/images/ansible"
LIBVIRT_CONFIG_PATH="/etc/libvirt/libvirtd.conf"


print_usage_help() {
  echo "Error: unrecognized option(s): $POSITIONAL"
  echo ""
  echo "Usage:"
  echo "   -s | --test-scenario  kvm"
  echo "   Test scenario"
  echo "   -p | --kvm-image-path /var/lib/libvirt/images/"
  echo "   Set a custom path to images for kvm /path/to/images/files/, default: /var/lib/libvirt/images/. \
  Affects only for kvm scenario"
  exit 1
}

fatal_error() {
  printf "%s\n" "$1"
  exit 1
}

while [[ $# -gt 0 ]]; do
  KEY="$1"

  case $KEY in
  -s | --test-scenario )
    TEST_SCENARIO="$2"
    shift
    shift
    ;;
  -p | --kvm-image-path )
    KVM_IMAGES_PATH="$2"
    shift
    shift
    ;;
  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done


echo "${POSITIONAL[@]}"

# error handling
for VALUE in "${POSITIONAL[@]}"
do
  if [[ -n $VALUE ]]; then
    print_usage_help
  fi
done

if [[ $TEST_SCENARIO != "default" ]] && [[ $TEST_SCENARIO != "kvm" ]]; then
  print_usage_help
fi

# install requirements
if [[ -f "$HOME"/.ansible_molecule_default_environment_ok ]]; then
  echo "Looks like ansible molecule environment for default scenario ok, file " \
    "'$HOME/.ansible_molecule_default_environment_ok' exists."
else
  printf "Setting up pip environment for 'default' scenario of ansible lint and testing...\n\n"
  PYTHON_VERSION=$(python3 -V | awk '{print $2}' | sed -r 's|..[0-9]$||') || exit 1
  python3 -m pip install -r "python_${PYTHON_VERSION}_${TEST_SCENARIO}_requirements.txt" || \
    fatal_error "Error installing python_${PYTHON_VERSION}_${TEST_SCENARIO}_requirements.txt pip requirements."
  echo "Executing 'ansible --version'..."
  ansible --version || fatal_error "Something went wrong with ansible installation."
  echo "Executing 'ansible-lint --version'..."
  ansible-lint --version || fatal_error "Something went wrong with ansible-lint installation."
  echo "Executing 'molecule --version'..."
  molecule --version || fatal_error "Something went wrong with ansible molecule installation."
  touch "$HOME/.ansible_molecule_default_environment_ok"
fi

if [[ $TEST_SCENARIO == "kvm" ]]; then
  # check if kvm environment is already installed
  if [[ -f "$HOME"/.ansible_molecule_kvm_environment_ok ]]; then
      echo "Looks like ansible molecule environment for kvm scenario ok, file " \
        "'$HOME/.ansible_molecule_kvm_environment_ok' exists."
      exit 0
  fi
  # check folder and permissions
  printf "Setting up pip environment for 'kvm' scenario of ansible lint and testing...\n\n"
  if [[ -d "$KVM_IMAGES_PATH" ]]; then
    echo "Path for kvm images $KVM_IMAGES_PATH already exists."
  else
    sudo mkdir -p "$KVM_IMAGES_PATH" || fatal_error "Error. Unable to create $KVM_IMAGES_PATH directory"
  fi

  if [[ $(stat -c "%U" "$KVM_IMAGES_PATH") == $(whoami) ]]; then
    echo "Folder $KVM_IMAGES_PATH already owned by $(whoami) user."
  else
    sudo chown "$(whoami)":"$(whoami)" "$KVM_IMAGES_PATH" || \
      fatal_error "Error. Unable to change owner for $KVM_IMAGES_PATH directory."
    echo "Folder $KVM_IMAGES_PATH owned by $(whoami) user"
  fi

  if [[ $(stat -c "%a" "$KVM_IMAGES_PATH") == "755" ]]; then
    echo "You have permissions to use with virt-customize already."
  else
    sudo chmod 775 "$KVM_IMAGES_PATH" || \
      fatal_error "Error. Unable to change permissions for $KVM_IMAGES_PATH directory."
    echo "You have successfully obtained permissions to use $KVM_IMAGES_PATH with $(whoami)"
  fi

  # check current user in libvirt group
  if [[ "$(id -Gn)" == "$(sudo cat $LIBVIRT_CONFIG_PATH | grep ^unix_sock_group | tr -d '"' | \
    awk '{print $3}')" ]]; then
      echo "$(whoami) is in the libvirt group already."
  else
    sudo usermod -aG "$(sudo cat $LIBVIRT_CONFIG_PATH | grep ^unix_sock_group | tr -d '"' | awk '{print $3}')" \
      "$(whoami)"
    echo "Successfully added $(whoami) to libvirt group."
  fi

  # check kvm default network
  if sudo virsh net-list | grep -q default; then
    echo "Default kvm network already exist. Skipping creation..."
  else
    set -e
    sudo virsh net-create default_kvm_net.xml
    sudo virsh net-autostart default
    sudo virsh net-start default
    set +e
    echo "Default kvm network was successfully created."
  fi

  # change vmlinuz permissions
  if [[ $(lsb_release -i | awk '{print $3}') == "Ubuntu" ]]; then
    sudo chmod 644 /boot/vmlinuz-"$(uname -sr | awk '{print $2}')" || \
      fatal_error "Unable to change vmlinuz $(uname -sr | awk '{print $2}') image permissions."
  fi
  echo "Successfully installed ansible molecule environment for kvm scenario."
  touch "$HOME/.ansible_molecule_kvm_environment_ok"

  # check ssh key
  if [[ $(ls -al "$HOME"/.ssh 2>&1 /dev/null) ]]; then
    echo "$HOME/.ssh already exists."
  else
    echo "$HOME/.ssh directory is absent, creating..."
    mkdir "$HOME"/.ssh || fatal_error "Error. Unable to create $HOME/.ssh"
  fi
  if [[ $(ls -al "$HOME"/.ssh && ls "$HOME"/.ssh/id_rsa && ls "$HOME"/.ssh/id_rsa.pub) ]]; then
    echo "ssh keys already exists."
  else
    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1 || \
      fatal_error "Unable to create ssh keys in $HOME/.ssh"
  fi
fi
