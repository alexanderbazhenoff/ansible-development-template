# ansible development template

Шаблон для соглашения при написании кода (contributing arrangements), GitLab CI, скрипты и пример структуры проекта, 

![CI](https://github.com/alexanderbazhenoff/ansible-development-template/actions/workflows/lint.yml/badge.svg?branch=main)

## О репозитории

Организуйте свой процесс разработки и произведите рефакторинг вашего ansible проекта вместе с:

- примером раскладки файлов и каталогов;
- шаблонами для правил (или соглашений) при написании кода;
- готовыми к использованию `gitlab-ci.yml` и скриптами для:
  - установки ansible окружения и необходимых для KVM настроек,
  - скрипт-обертка для [ansible lint](https://ansible-lint.readthedocs.io/),
  - скрипт для проверки учетных дынных в inventory-файлах (больше не будет забытых логинов и паролей),
  - скрипт-обертка для [ansible sanity testing](https://docs.ansible.com/ansible/latest/dev_guide/testing_sanity.html),
  - скрипт-итератор для тестирования ansible-ролей c использованием 
    [ansible molecule](https://molecule.readthedocs.io/en/latest/),
  - автоматическое увеличение версии вашей коллекции (коллекций) ansible,
  - git push в основную ветку после успешного тестирования и увеличения версии.

## Техническая информация

Этот CI и скрипты выполняют различные виды тестирования с использованием docker (предпочтительный сценарий тестирования
для ansible molecule) и KVM (для специальных системных ролей, таких как установка ядра, selinux и т. д.). Если вы хотите
использовать другой сценарий, вы можете ответвиться и добавить свой, потому как существует множество драйверов для
ansible molecule тестирования, таких как [kvm](https://github.com/alexanderbazhenoff/molecule-libvirt-delegated),
[podman](https://github.com/ansible-community/molecule-podman),
[kubevirt](https://github.com/ansible-community/molecule-kubevirt),
[docker-aws](https://github.com/jonashackt/molecule-ansible-docker-aws), 
[VMware](https://github.com/ansible-community/molecule-vmware), 
[vagrant](https://github.com/ansible-community/molecule-vagrant), 
[Yandex Cloud](https://github.com/arenadata/ansible-module-yandex-cloud), и т.д.

На данный момент роли тестируются последовательно, но сценарии параллельны (требуется как минимум два GitLab раннера).
Требуемые системные ресурсы зависят от того, сколько экземпляров (docker и/или KVM) вы запускаете за одно тестирование 
отдельной ansible роли. Этот "ansible development template" находится в стадии разработки, но, тем не менее, он
уже стабилен в работе и получении результатов. Возможно, однажды он будет включать в себя поддержку других сценариев
тестирования и/или тестирование всех ролей будут работать параллельно.

## Использование

Этот проект распространяется по лицензии [MIT](LICENSE), вы можете использовать его в любом вашем проекте.

## Как пользоваться

1. Создайте ветки main and development (или, например, `develop`) со всеми файлами данного репозитория. Вам нужно
произвести все необходимые настройки в ветке "main" и уже затем ответвиться от нее в "development".
2. Переименуйте для правил (или соглашений) при написании кода, выбрав подходящий язык. Например:
[CONTRIBUTING_template_rus.md](CONTRIBUTING_template_rus.md) в `CONTRINBUTING.md`.
3. Установите ветки "development" и "main" защищенными 
([protected branches](https://docs.gitlab.com/ee/user/project/protected_branches.html)). Настройте ветку разработки
(develop) "веткой по умолчанию" (default branch), чтобы в дальнейшем добавлять в нее все ваши изменения (merge). При 
успешном прохождении тестирования и увеличении версии ansible коллекций при merge requrest'е в ветку "develop", все ваши
изменения из ветки "develop" будут добавлены в ветку "main" для дальнейшего использования.
4. Задайте ваш Project Access Token (`Project -> Settings -> Access Tokens`) в переменной `GITLAB_TOKEN` в файле
[`gitlab-ci.yml`](.gitlab-ci.yml) (см. [GitLab CI Predefined variables reference](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)).
5. Настройте ноды GitLab runner'ов и добавьте их в свой проект ansible со следующими тегами:
   - `ansible-lint` и `docker` для ansible lint и sanity тестирования. При желании вы можете настроить одну ноду 
   `ansible-lint` для выполнения только ansible lint на этой ноде. 
   - `ansible_molecule` и `docker` с заранее установленным docker engine для запуска дефолтного сценария тестирования
   [ansible molecule](https://molecule.readthedocs.io/en/latest/).
   - `ansible_molecule` и `kvm` с заранее установленным
   [kvm](https://en.wikipedia.org/wiki/Kernel-based_Virtual_Machine) для запуска не дефолтного KVM сценария тестирования
   [ansible molecule](https://molecule.readthedocs.io/en/latest/).
   - `ansible-push`, любая GitLab нода с [ssh ключами для доступа к GitLab](https://docs.gitlab.com/ee/user/ssh.html)
   для выполнения автоматических push'ей в основную ветку после успешного тестирования и увеличения версии во время
   merge request'а в ветку "development". Вам также следует создать специального пользователя, например. `Ansible CI`.
6. Не забудьте установить python на вашем GitLab runner'е под пользователем `gitlab-runner`. Некоторые команды в 
[`setup_ansible_environment.sh` скрипте](.scripts/setup_ansible_environment.sh) требуют sudo доступ без пароля (см.
[search](https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions)
'Passwordless sudo' темы). Прочтите правила при написании кода (contributing template) для получения дополнительной 
информации о том, как настроить среду. Если вы желаете использовать версию python, новее чем 3.9, вам необходимо создать
зависимости в `python_<your_python_version>_default_requirements.txt` и
`python_<your_python_version>_lvm_requirements.txt`, расположенных в папке [.scripts](.scripts).
7. Установите для переменной `PIP_REQUIREMENTS` в [.gitlab-ci.yml](.gitlab-ci.yml) значение `yes` для первого запуска,
чтобы установить все зависимости python pip, но вы должны быть готовы установить некоторые из них в ручную при возможном
сбое установки. После установки переключите эту переменную обратно на `no`, это сократит время тестирования.
8. Замените этот [README file](README.md) на ваш в соответствии с содержимым проекта.
9. Создайте ветку (ответвитесь от "develop" или "main") для внесения ваших первых изменений. Когда вы вносите изменения,
подписанные commit-сообщением `WIP`, ansible molecule тестирование выполняться не будет, будет запущена только проверка
учетных данных, sanity и проверка синтаксиса (lint). Прочтите файлы-шаблоны правил при написании кода
([английская](CONTRIBUTING_template_eng.md) или [русская (CONTRIBUTING_template_rus.md) версии), как разрабатывать по 
стандартам ansible galaxy. При нажатии будут тестироваться только измененные роли ansible. Но если вы создадите 
мерж-реквест, все роли в вашем репозитории будут протестированы еще раз. Чтобы освободить ресурсы, создавайте
мерж-реквест только после завершения работы с собственной веткой.
10. Когда вы запустите слияние изменений (mergre) в ветку "develop", начнется тестирование всех коллекций и ролей - как
сценариев KVM, так и сценариев по умолчанию (docker). Когда это слияние отправит ваши изменения в ветку "main",
тестирование начнется снова, но на этот раз будут проверены и протестированы только изменения. После успешной проверки и
тестирования CI изменит версию(и) коллекции(й) и отправит все изменения в ветку "main". 
    

### Contents

```
├── .scripts                                - папка с CI-скриптами
│   ├── ansible_lint.sh                     - скрипт ansible lint
│   ├── default_kvm_net.xml                 - дефолтные настройки сети для KVM
│   ├── inventory_credentials_checker.sh    - скрипт для проверки учетных дынных в inventory-файлах
│   ├── perform_ansible_testing.sh          - скрипт для тестирования, изменения версий и autopush в main
│   ├── python_3.8_default_requirements.txt - зависимости python3.8 для сценария molecule по умолчанию
│   ├── python_3.8_kvm_requirements.txt     - зависимости python3.8 для KVM сценария molecule
│   ├── python_3.9_default_requirements.txt - зависимости python3.9 для сценария molecule по умолчанию
│   ├── python_3.9_kvm_requirements.txt     - зависимости python3.8 для KVM сценария molecule
│   └── setup_ansible_environment.sh        - скрипт для установки окружения ansible
│
├── .ansible_collections                    - пример раскладки файлов и каталогов для ansible-коллекций
│   ├── ...
│     ...
│
├── .ansible-lint                           - общие настройки ansible-lint
├── .gitignore                              - файл gitignore
├── gitlab-ci.yml                           - файл GitLab CI
├── .yamllint                               - общие настройки yamllint
├── CONTRIBUTING_template_rus.md            - правила и соглашения при написании кода на русском языке
├── markdownlint.json                       - настройки markdown lint для всего проекта
├── LICENSE                                 - файл лицензии
├── README.md                               - этот файл на английсокм языке
└── README_RUS.md                           - этот файл на русском языке 
```
