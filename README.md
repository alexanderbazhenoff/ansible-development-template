# ansible development template

Template for ansible development with CI.

### TLDR

This template is the way to organize your ansible development process and set-up CI for lint, credentials check in
inventory, ansible sanity and ansible molecule testing.

### Usage

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

5. Set-up `PIP_REQUIREMENTS` variable in [.gitlab-ci.yml](.gitlab-ci.yml) to `yes` for the first run to install all 
python pip requirements, but you should be ready to install some of them if broken. Switch this variable back to `no`,
this will decrease testing time.
6. Create branch with your first changes to push in. When you push with `wip` commit message no molecule testing 
available, just only credentials check, sanity and lint. Read 'contributing' file(s) how to develop according to ansible
galaxy standards.
7. When you finish merge your changes to develop branch, whis will start testing of all collections and roles both kvm 
and default (docker) scenarios. When you merge your branch into develop branch testing will start again. This time only
changes will be tested (like you're pushing in your working branch). At the end CI will change collection version(s)
with changes and push them to main branch.
