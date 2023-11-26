![CI](https://github.com/alexanderbazhenoff/ansible-development-template/actions/workflows/lint.yml/badge.svg?branch=main?event=push)

# ansible development template

Contributing rules template, CI scripts, and folder structure examples for ansible development.

## About

Organize your development process and perform refactoring of your ansible project with:

- ansible project layout example;
- contributing rules template, which can serve as a reference guide;
- ready to use `gitlab-ci.yml` and scripts for:

  - set-up required ansible environment and [KVM-related settings](#technical-info),
  - a wrapper for [ansible lint](https://ansible-lint.readthedocs.io/), 
  - a script for inventory credentials checks (no left login or password anymore in your repository),
  - a wrapper for [ansible sanity testing](https://docs.ansible.com/ansible/latest/dev_guide/testing_sanity.html),
  - an iterator for ansible roles testing using [ansible molecule](https://molecule.readthedocs.io/en/latest/),
  - automated version increment of your ansible collection(s),
  - git push to the main branch after success testing and version increment.

## Technical info

These CI and scripts perform various kinds of testing using docker (preferred ansible molecule testing scenario) and KVM
(for special system roles like install kernel, selinux, etc...) If you wish to use another scenario you can fork and
add them, there are a lot of drivers for molecule testing like 
[kvm](https://github.com/alexanderbazhenoff/molecule-libvirt-delegated),
[podman](https://github.com/ansible-community/molecule-podman),
[kubevirt](https://github.com/ansible-community/molecule-kubevirt),
[docker-aws](https://github.com/jonashackt/molecule-ansible-docker-aws), 
[VMware](https://github.com/ansible-community/molecule-vmware), 
[vagrant](https://github.com/ansible-community/molecule-vagrant), 
[Yandex Cloud](https://github.com/arenadata/ansible-module-yandex-cloud), etc...

At this moment, roles testing sequentially, but scenarios are parallel (required at least two GitLab runners). 
System resources depend on how many instances (docker and/or KVM) you run per single role testing. This 'ansible 
development template' is in progress, but already stable in running and getting results. Maybe one day this will include
support for other testing scenarios and/or will be able to run all roles testing in parallel.

## Usage

This project is distributed under the [MIT](LICENSE) license, you can use it in any of your projects.

## How to

1. Create main and development branches (or `develop`) including files from this repository. You should perform all
initialization changes in 'main' then fork it with development branch.
2. Rename contributing template choosing your appropriate language, e.g. 
[CONTRIBUTING_template_eng.md](CONTRIBUTING_template_eng.md) to `CONTRINBUTING.md`.
3. Set your development and 'main' branches as 
[protected](https://docs.gitlab.com/ee/user/project/protected_branches.html). Set up development branch as default to
merge all your changes in it. On success testing and version increment of ansible role(s) during merge request to
development branch, all your changes will merge into 'main' branch for further usage. 
4. Paste your Project Access Token (`Project -> Settings -> Access Tokens`) to `GITLAB_TOKEN` variable in 
[`gitlab-ci.yml`](.gitlab-ci.yml) file (see. [GitLab CI Predefined variables reference](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)).
5. Set-up GitLab runner nodes and add them to your ansible project including the next tags:
   - `ansible-lint` and `docker` for ansible lint and sanity tests. Optionally, you can setup single `ansible-lint` node
   to perform only ansible lint on separate node.
   - `ansible_molecule` and `docker` with docker engine installed to perform a default docker scenario of 
   [ansible molecule](https://molecule.readthedocs.io/en/latest/) testing.
   - `ansible_molecule` and `kvm` with [kvm](https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine) installed to
   perform a non-default KVM scenario of [ansible molecule](https://molecule.readthedocs.io/en/latest/) testing.
   - `ansible-push`, an any node with GitLab runner and 
   [GitLab ssh access keys](https://docs.gitlab.com/ee/user/ssh.html) to perform automated pushes to the main branch
   after success testing and version increment during merge request to 'develop' branch. You should also create a
   special user for, e.g. `Ansible CI`.
6. Remember to install python on GitLab runner nodes under `gitlab-runner` user. Some commands in 
   [`setup_ansible_environment.sh` script](.scripts/setup_ansible_environment.sh) requires sudo access without 
a password (you can 
[search](https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions)
'Passwordless sudo' topics). Read 'contributing' template file for more information on how to set your environment. If
you wish to use a newer version of python than 3.9, you also need to create requirements in
`python_<your_python_version>_default_requirements.txt` and `python_<your_python_version>_lvm_requirements.txt` files,
placed in the [.scripts](.scripts) folder.
7. Set-up `PIP_REQUIREMENTS` variable in [.gitlab-ci.yml](.gitlab-ci.yml) to `yes` for the first run to install all
python pip requirements, but you should be ready to install some of them manually on possible installation fail. After
setup switch this variable back to `no`, this will decrease testing time.
8. Replace this [README file](README.md) to yours according to your project contents.
9. Create branch (fork from 'develop' or 'main') with your first changes to push in. When you push changes signed by
`WIP` commit message ansible molecule testing will not be performed, just only credentials check, sanity and lint. Read
'contributing' file(s) ([English](CONTRIBUTING_template_eng.md) or [Russian (CONTRIBUTING_template_rus.md) versions) how
to develop, according to Ansible Galaxy standards. On push only changed ansible roles will be tested. But if you create
a merge request, all roles in your repository will be tested once again. To free up resources, create merge request only
when you complete working with your own branch.
10. When you apply merging your changes to 'develop' branch, testing of all collections and roles both kvm and default
(docker) scenarios will start. When this merge pushes your changes to the 'main' branch, testing will start again, but
this time only changes will be tested. After successful checking and testing, CI will change collection(s) version(s) 
and push all changes to the 'main' branch.

### Contents

```
├── .scripts                                - folder for CI scripts
│   ├── ansible_lint.sh                     - ansible lint script
│   ├── default_kvm_net.xml                 - settings for default KVM network
│   ├── inventory_credentials_checker.sh    - inventory credentials checker script
│   ├── perform_ansible_testing.sh          - testing script, version increment and push
│   ├── python_3.8_default_requirements.txt - python3.8 requirements for default molecule scenario
│   ├── python_3.8_kvm_requirements.txt     - python3.8 requirements for kvm molecule scenario
│   ├── python_3.9_default_requirements.txt - python3.9 requirements for default molecule scenario
│   ├── python_3.9_kvm_requirements.txt     - python3.9 requirements for kvm molecule scenario
│   └── setup_ansible_environment.sh        - set-up ansible enviromnent script
│
├── .ansible_collections                    - example of ansible collection(s) folder structure
│   ├── ...
│     ...
│
├── .ansible-lint                           - ansible-lint settings for the whole collections
├── .gitignore                              - gitignore file
├── gitlab-ci.yml                           - GitLab CI file
├── .yamllint                               - yamllint settings for the whole collections
├── CONTRIBUTING_template_rus.md            - CONTRIBUTING.md project template (ru)
├── LICENSE                                 - LICENSE file
├── markdownlint.json                       - markdownlint for the whole project
├── README.md                               - this file in English
└── README_RUS.md                           - this file in Russian 
```