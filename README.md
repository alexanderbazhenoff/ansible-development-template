# ansible development template

Template for ansible development with CI, CONTRIBUTING template and folder structure example(s).

## TLDR

This template is the way to organize your ansible development process and set-up CI for 
[lint](https://ansible-lint.readthedocs.io/), inventory credentials check (no left login or password anymore in your
repository when you develop your role!),
[ansible sanity](https://docs.ansible.com/ansible/latest/dev_guide/testing_sanity.html) and
[ansible molecule](https://molecule.readthedocs.io/en/latest/) testing. Also automated version increment of your
ansible collection and push to main branch on success testing.

## Preamble

Most of the people who came develop ansible are not so experienced programmers, so lots of syntax warnings and typo
available. If you don't wish to get eye ache and merge not-so-good ansible roles that one day broke your infrastructure,
you're wellcome to use this.

## Technical info

This CI and scripts perform various kinds of testing using docker (preferred ansible molecule testing scenario) and KVM
(for special system roles like install kernel, selinux, etc...) If you wish another one feel free to fork and add them,
there are a lot of drives for molecule testing like 
[kvm](https://github.com/alexanderbazhenoff/molecule-libvirt-delegated),
[podman](https://github.com/ansible-community/molecule-podman),
[kubevirt](https://github.com/ansible-community/molecule-kubevirt),
[docker-aws](https://github.com/jonashackt/molecule-ansible-docker-aws) (perhaps the expensive one), 
[VMware](https://github.com/ansible-community/molecule-vmware), 
[vagrant](https://github.com/ansible-community/molecule-vagrant), 
[Yandex Cloud](https://github.com/arenadata/ansible-module-yandex-cloud), etc...

At this moment roles testing sequentially, but scenarios are parallel (required at least two GitLab runners). Required 
resources depends on how many instances (docker and/or KVM) you run per single role testing. This ansible template 
project is in development progress, but quite stable in running and resulting. May be one day this will support other 
testing scenarios and/or will be able to run in parallel.

## Usage

1. Create main and development branches (e.g. `develop`) including this files. Also rename contributing template, e.g.
[CONTRIBUTING_template_rus.md](CONTRIBUTING_template_rus.md).
2. Protect development branch.
3. Paste your Project Access Token (`Project -> Settings -> Access Tokens ) to `GITLAB_TOKEN` variable in 
[.gitlab-ci.yml](.gitlab-ci.yml) file.
4. Set-up nodes with GitLab runners and add them to the project with the next tags:
   - `ansible-lint` and `docker` for ansible lint and sanity tests. Optionally setup single `ansible-lint` node to 
   perform only ansible lint on separate node.
   - `ansible_molecule` and `docker` with docker installed to perform default docker scenario of 
   [ansible molecule](https://molecule.readthedocs.io/en/latest/) testing.
   - `ansible_molecule` and `kvm` with [kvm](https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine) installed to
   perform default docker scenario of [ansible molecule](https://molecule.readthedocs.io/en/latest/) testing.
   - `ansible-push` any node with GitLab runner with [GitLab ssh keys](https://docs.gitlab.com/ee/user/ssh.html) to
   perform automated pushes. You should also create a special user for, e.g. `Ansible CI`.
5. Don't forget to install python on your GitLab runners under your `gitlab-runner` user. Most molecule and other 
related modules requires access under user without sudo. Read 'contributing' template file for more information how to 
set your environment. If you wish to use later than python3.9 you also need to create `requirements*.txt` files in the
[.scripts](.scripts) folder.
6. Set-up `PIP_REQUIREMENTS` variable in [.gitlab-ci.yml](.gitlab-ci.yml) to `yes` for the first run to install all 
python pip requirements, but you should be ready to install some of them if broken. Switch this variable back to `no`,
this will decrease testing time.
7. Replace this README file to yours according to your project contents.
8. Create branch with your first changes to push in. When you push with `WIP` commit message no molecule testing will be 
performed, just only credentials check, sanity and lint. Read 'contributing' file(s) how to develop according to ansible
galaxy standards. On push only changes will be tested, but if you create a merge request all project roles will be 
tested once again in parallel. Create merge request only when you complete working with your own branch. 
9. When you finish merge your changes to develop branch, testing of all collections and roles both kvm and default
(docker) scenarios will start. When you merge your branch into develop branch testing will start again. This time only
changes will be tested (like you're pushing in your working branch). At the end CI will change collection version(s)
with changes and push them to main branch.

### Contents

```
├── .scripts                                 - folder for CI scripts
│   ├── ansible_lint.sh                     - ansible lint script
│   ├── default_kvm_net.xml                 - settings for default KVM network
│   ├── inventory_credentials_checker.sh    - inventory credentials checker script
│   ├── perform_ansible_testing.sh          - testing script, version increment and push
│   ├── python_3.8_default_requirements.txt - python3.8 requirements for default molecule scenario
│   ├── python_3.8_kvm_requirements.txt     - python3.8 requirements for kvm molecule scenario
│   ├── python_3.9_default_requirements.txt - python3.9 requirements for default molecule scenario
│   ├── python_3.9_kvm_requirements.txt     - python3.8 requirements for kvm molecule scenario
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
└── README.md                               - this file
```
