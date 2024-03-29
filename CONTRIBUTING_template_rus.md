# Правила и соглашения при написании кода

---

Данные правила и соглашения составлены с целью упорядочить процессы разработки, а так же ознакомить со стандартами
и практиками для понимания концепции разработки ansible ролей и playbook'ов. Перед началом работы с проектом 
настоятельно рекомендуется ознакомиться с данными правилами. Приступая к работе с данным проектом, вы автоматически
соглашаетесь с нижеизложенным.

## Базовые правила при работе с проектом

Для улучшения восприятия кода, упрощения его последующей поддержки и сохранения его в работоспособном состоянии 
следует соблюдать основные правила:

1. Все, устанавливаемое и(или) настраиваемое на Linux системах, что может быть установлено и(или) настроено с помощью
ansible, рано или поздно должно быть автоматизировано, что устанавливаться, или настраиваться с помощью ansible.
Для упрощения запуска могут быть использованы wrappers в виде
[jenkins pipelines](https://www.jenkins.io/pipeline/getting-started-pipelines/). 
2. Работа с gitlab-репозиторием и весь процесс разработки должны осуществляться согласно правилам, изложенным в пункте
["Работа с gitlab проектом"](#работа-с-gitlabgithub-проектом).
3. Содержание данного gitlab-репозитория должно поддерживаться с сохранением структуры, изложенной в пункте
["Требования к структуре и контенту проекта"](#требования-к-структуре-и-контенту-проекта).

## Поддерживаемые дистрибутивы

Поддерживаемые Linux дистрибутивы:
```
< список дистрибутивов >
```

В случае технической необходимости допускается поддержка других дистрибутивов Linux. Если для работоспособности роли на
всех других версиях данного семейства (`ansible_os_familty`) достаточно сформировать ссылку на репозиторий из 
ansible-фактов (например: `ansible_distribution` и `ansible_distribution`), то поддержка других дистрибутивов
приветствуется.

## Требования к структуре и контенту проекта

1. Структура проекта должна быть единообразной для всех ролей, playbook'ов, тестов, скриптов и соответствовать 
   стандартам Ansible Galaxy (см. ["Структура проекта"](#структура-проекта)).
2. Код должен быть написан в соответствии с требованиями к его написанию и проходить все lint- и sanity-проверки (см.
   ["CI проекта"](#ci-проекта)):
   - Если в скриптах, или тестах используется python, то код должен проходить все
   lint-проверки [flake8](https://flake8.pycqa.org/en/latest/) (дополнительно см. ["CI проекта"](#ci-проекта) и
   ["Структура ansible molecule тестов"](#структура-ansible-molecule-тестов)).
   - Если в скриптах используется bash, то код должен проходить все проверки shellcheck. Для большинства IDE, как,
     например, IDE от JetBrains имеются [плагин](https://plugins.jetbrains.com/plugin/10195-shellcheck), для Gitlab CI
     имеется стадия тестирования "pre-check" (см. [CI проекта](#ci-проекта)).
   - Если какой-либо из скриптов будет написан на любом другом языке, отличном от ansible, python, или bash, то так же
     должен проходить все проверки синтаксиса: модифицируется [CI проекта](#ci-проекта), или тестируется отдельно в
     рамках ["molecule testing"](#структура-ansible-molecule-тестов), в зависимости от предназначения и расположения его
     кода.
   - Все поля файлов метаданных (таких, как
     [meta/main.yml](https://docs.ansible.com/ansible/latest/galaxy/user_guide.html#galaxy-dependencies) и
     [galaxy.yml](https://docs.ansible.com/ansible/latest/dev_guide/collections_galaxy_meta.html)) должны быть корректно
     заполнены.
   - Каждая роль должна быть сопровождена файлом-описанием README.md с указанием названия роли, зависимостей, описанием
     переменных, примерами использования роли, информации об авторах и лицензии. Структура такого описания должна быть
     максимально понятной для использования ansible-роли без просмотра её кода.
   - Каждая ansible Galaxy коллекция должна включать файл лицензии LICENSE под которой она распространяется. Если 
     какая-то из ролей в коллекции была выпущена под другой лицензией (или, например, forked с внешних источников), то
     оригинальная лицензия сохраняется и помещается в папку роли. Для forked-ролей так же приветствуется указывание
     оригинального автора и ссылки.
3. Код должен выполняться и производить все необходимые установки и настройки одинаково качественно и в полном объеме
   для всех используемых на данный момент 
   [поддерживаемых в проекте дистрибутивах и системах](#поддерживаемые-дистрибутивы). 
4. Код должен быть покрыт тестами, которые в любой момент успешно проходят:
    - Все ansible-роли должны быть покрыты ansible molecule тестами (см.
      ["Правила написания ansible molecule тестов"](#правила-написания-ansible-molecule-тестов));
    - Проект должен проходить все фазы тестирования (см. ["CI проекта"](#ci-проекта)). При необходимости виды
      тестирования (или Gitlab CI stages могут быть изменены и расширены).
5. Код должен быть написан в соответствии с общепринятыми в программировании правилами.
6. Код должен содержать понятные и осмысленные комментарии, описания и имена переменных.
7. Комментарии, файлы метаданных, описаний, имена переменных и файлов не должны содержать нецензурных выражения,
   оскорбления, призыву к насилию (исключением может быть традиционная для linux команда `kill`), противоправные
   действиям и иные нарушения морально-этических норм.
8. Если какой-то фрагмент кода может быть упрощен с сохранением выполняемых им функций, то этот фрагмент кода должен
   быть упрощен, или оптимизирован (refactored).
9. Поскольку каждая роль в коллекции должна сохранять способность запуска вне зависимости от других ролей и ее 
   расположения в коллекции (в виде исключения допускаются лишь тесты роли), допускается размещение одинаковых файлов
   внутри каждой роли, например: драйвера molecule test'ов (molecule-libvirt-delegated), dockerfile'ов и т.д.
10. Любая ansible Galaxy коллекция из этого репозитория должна собираться для последующей установки из директории этой
    коллекции в данном репозитории (команда `ansible-galaxy collection build`, см.
    [["ansible collections"](#ansible-collections)).

## Правила написания ansible molecule тестов

1. Все ansible роли должны быть покрыты успешно проходящими тестами.
2. Тестирование роли должно покрывать, как минимум, вызов роли с параметрами по умолчанию и, а так же 
   работоспособность программного компонента, пакета, системы, или сервиса, для которого написана эта роль, на предмет
   корректной установки и(или) настройки.  
3. Тестирование роли должно производится на [дистрибутивах и системах](#поддерживаемые-дистрибутивы), используемых в
   данный момент в инфраструктуре.
4. На вызов ролей при тестировании, а так же создание и удаление instance'в, расходуется время (особенно запуск всех 
   тестов), которое должно быть оптимизировано там, где это возможно, без ущерба результатам и качеству тестирования.
5. Все molecule тесты должны быть написаны с соблюдением правил, изложенных в разделе
   ["Структура ansible molecule тестов"](#структура-ansible-molecule-тестов).
6. Все тесты должны успешно проходить в актуальном для текущего процесса разработки окружении (настроенном на системе, 
   где создаются instances, см.
["Установка и настройка окружения ansible и molecule ansible"](#установка-и-настройка-окружения-ansible-и-molecule-ansible)).

## Работа с GitLab/GitHub проектом

В первую очередь, если это не сделано до работы с репозиторием, необходимо настроить ssh ключи:

- [Создание нового ключа SSH и его добавление в ssh-agent](https://docs.github.com/ru/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).
- [Use SSH keys to communicate with GitLab](https://docs.gitlab.com/ee/user/ssh.html).
- [Добавление нового ключа SSH в учетную запись GitHub](https://docs.github.com/ru/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

После получения исходников в репозитории [GitLab](https://docs.gitlab.com/) создается новая ветка вида `f_NNNNNN`,
или `b_NNNNNN`, где `NNNNN` - номер задачи в используемом task tracker'е. По завершении работы над задачей создается 
Merge Request в дефолтную ветку ('devel', или 'develop') и назначается на Maintainer'ов. В заголовке Merge Request'а 
коротко и понятно указывают, что было изменено, или над чем велась работа. Опционально в скобках можно указать номер
задачи в task tracker'е, например:

> Postgresql installation on Ubuntu has been fixed (b_1234)

Все остальные детали о проведенных работах и изменениях указываются в описании (Description). Все commits squash'атся
(Squash commits when merge request is accepted), а ветка в которой велась работа (при условии, что она закончена)
удаляется (опция "remove source branch when merge request is accepted").

Далее maintainer'ы проверяют изменения и пишут замечания по исправлению тем, кто работал над задачей (изменениями).
После исправления замечаний maintainer'ы вносят изменения в дефолтную ветку (merge в 'devel', или 'develop')) и при
прохождении [всех стадий CI](#ci-проекта) эти изменения автоматически попадают в master (или main).

Необходимо так же учитывать:

- Если изменения в данном проекте влияют на выполнение вызов и параметры этой роли с помощью Jenkins wrapper pipeline 
  (при условии, что таковой существует), то изменения так же должны быть внесены в соответствующий код wrapper pipeline.
  Процесс внесения изменений аналогичный.
- Если изменения в данном проекте влияют так же на выполнение playbook'ов (в директории коллекции `playbooks`), которые
  эти изменения вызывают, то playbooks должны быть так же актуализированы.

[Процесс разработки](https://docs.github.com/en/get-started/quickstart/github-flow) в 
[GitHub](https://docs.github.com/ru/get-started/quickstart) во многом схож с процессом в GitLab за исключением того, что
вместо Merge Request (MR) создается Pool Request (PR) в ветку по умолчанию и проект, от которого было произведено
ответвление. *CI данного шаблона для разработки ansible-коллекций в настоящий момент не содержит CI для GitHub.*

## Структура проекта

Директория проекта состоит:

| Файл/Папка             | Описание                                                          |
|------------------------|-------------------------------------------------------------------|
| `.scripts/`            | CI скрипты, файлы pip requirements, xml для KVM network           |
| `ansible_collections/` | коллекции ansible                                                 |
| `inventories/`         | inventory-файлы и статичные описания инфраструктуры (опционально) |
| `.ansible-lint`        | файл конфигурации ansible-lint                                    |
| `.gitlab-ci.yml`       | файл Gitlab CI                                                    |
| `.yamllint`            | файл конфигурации yaml-lint                                       |
| `CONTRIBUTING.md`      | этот файл                                                         |
| `README.md`            | файл readme                                                       |

Согласно [стандартам](https://docs.ansible.com/ansible/latest/galaxy/dev_guide.html) для
[ansible galaxy](https://galaxy.ansible.com/) структура директории `ansible_collections` должна выглядеть следующим
образом:

```
ansible_galaxy/
├── namespace1                                              # папка для ansible galaxy namespace 'namespace1'
│    └── collection_name1                                   # папка для ansible-коллекции collection_name1
│        ├── galaxy.yml                                     # метаданные для collection_name1
│        ├── LICENSE                                        # файл-лицензия для collection_name1
│        ├── playbooks                                      # папка для ansible-плейбуков в collection_name1
│        │       ├── playbook1.yml                          # ansible-плейбук playbook1
│        │       ├── playbook2.yml                          # ansible-плейбук playbook2
│        │       └── inventory                              # inventory файл (опционально)
│        ├── README.md                                      # инфо файл для коллекции collection_name1
│        ├── requirements.yml                               # файл requirements для collection_name1
│        ├── roles                                          # папка для ansible-ролей
│        │       ├── role_name1                             # папка для ansible-роли role_name1
│        │       │       ├── role_name1_example.yml         # playbook-пример для запуска роли (опционально)
│        │       │       ├── meta                           # папка для meta-описание роли
│        │       │       │    └── main.yml                  # meta-описание роли в формате ansible galaxy
│        │       │       ├── molecule                       # папка с ansible molecule сценариями
│        │       │       │    └── default                   # папка default сценария ansible molecule
│        │       │       │         ├── cleanup.yml          # clean-up stage для ansible molecule
│        │       │       │         ├── converge.yml         # converge stage для ansible molecule
│        │       │       │         ├── create.yml           # create stage для ansible molecule
│        │       │       │         ├── Dockerfile.j2        # dockerfile для ansible molecule instance
│        │       │       │         ├── INSTALL.rst          # описание подготовки окружения для тестирования
│        │       │       │         ├── molecule.yml         # конфигурация сценария default для molecule
│        │       │       │         ├── prepare.yml          # prepare stage для ansible molecule
│        │       │       │         ├── requirements.txt     # pip requirements файл для тестирования
│        │       │       │         ├── requirements.yml     # ansible molecule requirements файл
│        │       │       │         ├── side_effect.yml      # side effect stage для ansible molecule
│        │       │       │         ├── verify.yml           # verify stage для molecule (если не testinfra)
│        │       │       │         └── tests                # диркетория с тестами для pytest-testinfra
│        │       │       │              └── test_default.py # тест для pytest-testinfra
│        │       │       ├── README.md                      # файл-описания роли в формате markdown
│        │       │       ├── LICENSE                        # лицензия для роли (если отличается от коллекции)
│        │       │       ├── tasks                          # папка для tasks для роли role_name1
│        │       │       │      └── main.yml                # main task для ароли role_name1
│        │       │       └── tests                          # папка для ansible-test
│        │       │            ├── inventory                 # файл inventory для ansible-test
│        │       │            └── test.yml                  # плейбук для ansible-test
│        │       │    
│        │       ├── role_name2                             # папка для role_name2
│        │       │    └── ...
│        │       └── ...
│        │
│        │── plugins                                        # папка для ansible плагинов 
│        │    └── ...
│        │
│        └── tests                                          # папка для тестов к плагинам
│             └── ...  
│   
├── namespace2                                              # папка для ansible galaxy namespace 'namespace2'
│    └── collection_name2                                   # папка для ansible-коллекции collection_name2
│         └── ...
└── ...
```
Часто в публичных репозиториях требуется расположение одной лишь коллекции без namespace и папки `ansible_collections`, 
однако это затрудняет запуск из этой папки ansible sanity tests (см. [CI проекта](#ci-проекта)). *CI данного шаблона для 
разработки ansible-коллекций в настоящий момент не поддерживает такую структуру проекта.*

### Galaxy Namespace

В качестве имени для ansible [Galaxy Namespace](https://galaxy.ansible.com/docs/contributing/namespaces.html), как
правило, выбирается автор, публикующая компания, компания или подразделение (например,
[community](https://docs.ansible.com/ansible/latest/collections/community/index.html), или
[ansible](https://docs.ansible.com/ansible/latest/collections/ansible/index.html)). В качестве namespace может быть так
же выбран и некий атрибут, признак, или свойство, объединяющее ansible-коллекции: например, часто используемые роли из 
разных источников - `common` (путь `ansible_collections/common/linux`).

### ansible collections

В качестве имени для коллекции можно выбрать технологию, сервис, область, или платформу для которой эта коллекция 
написана. Например:

- common.linux
- company_name.services
- company_name.access

Дополнительную информацию можно получить в 
['Collections Using'](https://docs.ansible.com/ansible/latest/user_guide/collections_using.html) на
[docs.ansible.com](https://docs.ansible.com/).

Для создания коллекции перейдите в необходимую папку (например: `cd ansible_collections/common/linux`) и выполните:
```bash
collection_dir#> ansible-galaxy collection init my_namespace.my_collection
```
Для сборки и установки для ее последующего использования в вашей системе:
```bash
collection_dir#> ansible-galaxy collection build
collection_dir#> ansible-galaxy collection install $(ls -1 | grep ".tar.gz")
```
Чтобы принудительно установить (ключ `-f`), указав имя архива:
```bash
ansible-galaxy collection install common-linux-x.y.z.tar.gz
```
При возникновении ошибки `ERROR! You must specify a collection name or a requirements file.` установку можно произвести
без создания архива ansible collection с указанием requirements-файла:
```bash
ansible-galaxy collection install $(ls -1 | grep ".tat.gz") -r ./requirements.yml -f
```

Более подробную информацию смотрите в 
['Developing Collections'](https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html).

### ansible roles

В качестве имени для [ansible-ролей](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
выбирается непосредственно то, что эта роль настраивает, или устанавливает. Если роль позволяет выбрать функционал, или
технологию, то название необходимо выбирать в соответствии с максимальным функционалом: например, если роль позволяет
установить как lxc, так и lxcfs, то роль следует назвать **"lxcfs"** (`ansible_collections/common/linux/roles/lxcfs`).

Для инициализации роли (создание структуры: всех каталогов и файлов-примеров) можно использовать команду:
```bash
role_dir#> ansible-galaxy init role_name
```
Но инициализация через команду molecule позволяет дополнительно создать еще и
[структуру для ansible molecule testing](#Структура-ansible-molecule-тестов):
```bash
role_dir#> molecule init role role_name
```

### ansible playbooks

Как правило, [ansible playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html) в данном проекте
являются неким собирательным сценарием вызывающем несколько ролей, или производящий группу разных действий, которые
невозможно, или не имеет смысла объединять в одну ansible роль. Playbook'и могут так же выполнять некоторые простейшие
действия. Во всех остальных случаях лучше использовать структуру ansible ролей.

### ansible inventory

[Ansible inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) используется в данном 
проекте для хранения описания всех хостов и их групп. Может так же быть создан внутри роли, или в той же папке, что 
и ansible playbook, для тестирования ansible роли при её написании и для ansible playbook соответственно. Удобней всего
ansible inventory с описанием инфраструктуры хранить вне коллекций, так как упрощается доступ при использовании ansible
playbook'ов и ролей отдельно от Jenkins pipeline wrapper'ов.

### ansible modules

При необходимости в ansible-коллекцию 
[могут быть добавлены](https://docs.ansible.com/ansible/latest/dev_guide/developing_locally.html#modules-vs-plugins)
и [ansible-модули](https://docs.ansible.com/ansible/latest/plugins/module.html). Для их тестирования
потребуется [ansible-test](https://docs.ansible.com/ansible/latest/dev_guide/testing.html), что в свою очередь потребует
изменений [Gitlab CI данного проекта](#ci-проекта).

### ansible test

Папка `test/` внутри папки роли, как правило, создается при создании структуры самой роли (но в 
[прилагаемом CI](#ci-проекта) для тестирования ролей используется
[ansible molecule](#Структура-ansible-molecule-тестов)), тогда как одноименная папка внутри коллекции уже может быть
использована для
[других видов тестирования](https://docs.ansible.com/ansible/latest/dev_guide/testing.html#types-of-tests). В первом
случае папку после автоматического её создания можно не удалять, тогда как во втором случае создавать ее следует по
необходимости. [CI данного проекта](#ci-проекта) в одной из стадий запускает ansible sanity tests, для которого папки
tests в каждой из ролей не требуются.

### Структура ansible molecule тестов

[Ansible molecule](https://molecule.readthedocs.io/en/latest/index.html) используется для тестирования ролей 
предоставляет возможность проводить тестирование роли в нескольких сценариях, в каждом из которых тестирование может 
быть произведено в определенном окружении. Например, как в данном проекте:
- **default**. Используется для тестирования ролей внутри
[docker-контейнеров](https://www.docker.com/resources/what-container/). В `molecule.yml` данного сценария 
указывается molecule драйвер 'docker' (в будущих версиях molecule - 
[molecule docker plugin](https://github.com/ansible-community/molecule-docker)), которому в свою очередь необходима
установленная
[community.docker ansible коллекция](https://docs.ansible.com/ansible/latest/collections/community/docker/index.html).
- **kvm**. Используется для тестирования через
[molecule-libvirt-delegated драйвер](https://github.com/geropizarro/molecule-libvirt-delegated), позволяющий тестировать
внутри Kernel-Based Virtual Machine. Используется там, где роль не может быть протестирована средствами docker. Чтобы
использовать этот драйвер, в папку kvm-сценария `molecule/kvm` следует поместить содержимое
[данного репозитория](https://github.com/geropizarro/molecule-libvirt-delegated) без папки `tests` (если 
[Pull Request](https://github.com/geropizarro/molecule-libvirt-delegated/pull/3) все еще не принят, то поместить fork).
Так же папку `molecule/kvm` можно скопировать из другой роли, изменив под свою задачу.

Если kvm сценарий является опциональным, то default является обязательным. Если провести тестирование роли внутри 
docker не возможно, то в папку со сценарием помещается create.yml (без tasks, но с header'ом), 
а так же`molecule.yml` следующего содержания:

```yaml

dependency:
  name: galaxy
  options:
    ignore-certs: True
    ignore-errors: True
driver:
  name: delegated
platforms:
  - name: none
scenario:
  test_sequence:
    - dependency
    - lint
    - syntax
provisioner:
  name: ansible
  env:
    PY_COLORS: '1'
    ANSIBLE_FORCE_COLOR: '1'
lint: |
    export ANSIBLE_ROLES_PATH=${MOLECULE_PROJECT_DIRECTORY}/..
    export PY_COLORS=1
    export ANSIBLE_FORCE_COLOR=1
    yamllint .
    ansible-lint .
```
Таким образом, в сценарии `default` будут проверены зависимости и синтаксис.

**Тестирование ролей с помощью ansible molecule непосредственно на хостовой системе недопустимо** - используйте docker,
или виртуальные машины KVM.

Каждый сценарий состоит из "test_sequence", где можно выделить следующие стадии, порядок которых указан в
[molecule.yml](https://molecule.readthedocs.io/en/latest/configuration.html):

- [**dependency**](https://molecule.readthedocs.io/en/latest/usage.html#dependency). Проверка всех ansible зависимостей
для тестирования (по умолчанию берутся из файла `requirements.yml`).
- [**lint**](https://molecule.readthedocs.io/en/latest/usage.html#init). Проверка синтаксиса через ansible-lint и
yamllint. Настройки для [ansible-lint](https://ansible-lint.readthedocs.io/en/latest/) и
[yamllint](https://yamllint.readthedocs.io/en/stable/index.html) берутся из файлов `.ansible-lint` и `.yamllint`,
которые необходимо размещать в каждой папке роли, в папке коллекции, а так же в корне этого репозитория. Фактически,
файлы должны быть размещены там, откуда чаще всего может быть запущены anisble-lint и yamllint, вне зависимости от того,
запущены они вручную, или же через сценарии molecule test.
- [**destroy**](https://molecule.readthedocs.io/en/latest/usage.html#destroy) (playbook по умолчанию: `destroy.yml`).
Удаление или очистка instance'ов. Playbook `destroy.yml` присутствует в kvm сценарии, но не требуется в default (docker)
сценарии.
- [**syntax**](https://molecule.readthedocs.io/en/latest/usage.html#syntax). Проверка синтаксиса.
- [**create**](https://molecule.readthedocs.io/en/latest/usage.html#create) (playbook по умолчанию: `create.yml`).
Создание instance'в. Playbook `create.yml` присутствует в kvm сценарии, но не требуется в default (docker) сценарии.
- [**prepare**](https://molecule.readthedocs.io/en/latest/usage.html#prepare) (playbook по умолчанию: `prepare.yml`).
Подготовка к тестированию. Используется в тех случаях, где предварительно нужно что-либо настроить, или установить.
- [**converge**](https://molecule.readthedocs.io/en/latest/usage.html#converge) (playbook по умолчанию: `converge.yml`).
Непосредственно само тестирование с вызовом роли и применением ее на instance'ах.
- [**verify**](https://molecule.readthedocs.io/en/latest/usage.html#verify) (playbook по умолчанию: `verify.yml`).
Проверка результата выполнения роли. Используется, если в `molecule.yml` в качестве verifyer'а указан ansible. В
качестве альтернативы допускается использование [testinfra](https://pypi.org/project/testinfra-bdd/) (в качестве
verifyer'а в `molecule.yml` указывается testinfra). С примерами использования можно ознакомиться
[здесь](https://testinfra.readthedocs.io/en/latest/examples.html). Если в качестве verifyer'а используется testinfra,
то в стадию lint так же добавляется проверка синтаксиса python скриптов с помощью
[flake8](https://flake8.pycqa.org/en/latest/), а в папку с ролью помещается файл настроек `.flake8`.
- [**side_effect**](https://molecule.readthedocs.io/en/latest/usage.html#side-effect). (playbook по умолчанию:
`side_effect.yml`). Внесение в тестирование некого random factor'а: применение изменений перед, или после применения 
роли (тест на стабильность), изменение условий тестирования, или каких-либо параметров, с которыми будет вызвана роль.
- [**idempotence**](https://molecule.readthedocs.io/en/latest/usage.html#idempotence). Фактически является тестом на
корректность получаемого при выполнении роли параметра `changed_when` для каждого шага при двукратном вызове converge:
если при повторном вызове роли хотя бы в одном шаге будет получен `changed_when: True`, то тест не пройдет. В данном
репозитории не используется за ненадобностью.

Подробней о [molecule scenarios](https://molecule.readthedocs.io/en/latest/getting-started.html#molecule-scenarios) и
[test sequence](https://molecule.readthedocs.io/en/latest/configuration.html#root-scenario) можно прочитать в
[документации](https://molecule.readthedocs.io/en/latest/)
[ansible molecule](https://www.ansible.com/blog/developing-and-testing-ansible-roles-with-molecule-and-podman-part-1).

Дополнительно в папку со сценариями (`molecule/default` и `molecule/kvm`) помещаются:

- `requirements.txt` - pip requirements необходимые для тестирования.
- `INSTALL.rst` - описание установки всего необходимого для тестирования в данном сценарии.
- `dockerfile.j2` - dockerfile для default сценария.

Аналогично структуре ролей допускается вложенность в сценарий папок: `files/`, `defaults/`, `vars/` и т.д.

## Установка и настройка окружения ansible и molecule ansible

Установка окружения производится как на локальной системе, где ведется разработка (для запуска тестирования локально),
так и на системах, где выполняются pipeline'ы Gitlab CI для данного проекта (вероятней всего, к моменту чтения 
удаленные системы уже готовы к использованию в Gitlab CI). На всех системах следует устанавливать одинаковые версии
ansible и ansible-lint, актуальных для текущего проекта.

### Установка ansible и ansible-lint:

```bash
python3 -m pip install whell setuptools ansible==2.10.7 ansible-lint==5.4.0
```
Обратите внимание, что пакет ansible-base, необходимый для ansible версии 2.10.x, конфликтует с ansible-core, 
необходимым для более новых версий ansible. Учитывайте эту особенность зависимостей при переходе проекта на 
[более новые версии](https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html). В 
противном случае конфликт можно разрешить с помощью удаления пакета ansible core:
```bash
python3 -m pip uninstall ansible-core
```
и переустановки ansible и всех его зависимостей:
```bash
python3 -m pip uninstall ansible ansible-base ansible-compat ansible-lint
```
Если python3 установлен через altinstall в пользовательскую директорию, то все ansible и ansible molecule окружение
устанавливается с ключом `--user` (актуально, кроме системных пакетов, таких как, например, selinux - они ставятся без
ключа). Драйверы molecule (такие, как, например, `molecule[docker]`) устанавливаются всегда с ключом `--user` вне 
зависимости от способа установки python.

Так же при установке от пользователя необходимо учитывать значение переменной PATH в зависимости от используемой
оболочки (bash, tcsh, zsh). Например, для [zsh](https://www.zsh.org/) в конец файла`~/.zshrc` необходимо добавить:
```bash
export PATH=$PATH:$HOME/.local/bin/
```
В противном случае при выполнении команд `ansible` (а так же `ansible-lint`, `ansible-galaxy` и т. д.) путь к 
ним может быть не найден.

Иногда какой-то из уже установленных пакетов pip может быть не найден. Просмотреть пути, по которым производится поиск
пакетов pip при импорте можно следующим образом:
```
$ python3
>>> import sys
>>> sys.path
```
При необходимости файлы пакета можно скопировать из одного пути в другой, выставив необходимые права.

### Настройка окружения для default сценария:

```bash
python3 -m pip install --upgrade --user setuptools
python3 -m pip install molecule install requests==2.23.0 Jinja2 yamllint docker molecule-docker
python3 -m pip install flake8 pytest pytest-testinfra
python3 -m pip install --user "molecule"
python3 -m pip install --user "molecule[delegated]==3.6.1"
python3 -m pip install --user "molecule[ansible-lint]"
python3 -m pip install --user "molecule[docker]"
```
В зависимости от версий python и pip дефолтные версии требуемых для окружения пакетов могут отличаться, что, например, в
случае с `molecule[delegated]` может привести к проблемам с подключением к docker images при запуске тестов. Поэтому 
указанные ниже версии являются проверенными и работоспособными:
```
$ molecule --version                                                                                                                                                                                                                                               
molecule 3.6.1 using python 3.9 
    ansible:2.10.8
    delegated:3.6.1 from molecule
    docker:1.1.0 from molecule_docker requiring collections: community.docker>=1.9.1
    libvirt:0.0.5 from molecule_libvirt
```

Так же необходимо, чтобы в системе был [установлен Docker Engline CE](https://docs.docker.com/engine/install/) и
пользователь, под которым производится тестирование, добавлен в группу `docker`:
```bash
sudo usermod -aG docker $(whoami)
```
### Настройка окружения для kvm сценария:

Для тестирования ролей в ansible molecule сценарии с использованием Kernel-based Virtual Machine требуется 
дополнительно (к пакетам для default сценария) установить некоторые зависимости и произвести настройки.

Установка пакетов pip:
```bash
python3 -m pip install libvirt-python molecule-libvirt lxml
```

[Установка](https://medium.com/@alexander.bazhenov/%D0%B2%D0%B8%D1%80%D1%82%D1%83%D0%B0%D0%BB%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D1%8F-%D0%B2-linux-%D1%87%D0%B0%D1%81%D1%82%D1%8C-1-kernel-based-virtual-machine-kvm-55f989880dbf) 
Kernel-based Virtual Machine для разных дистрибутивов будет несколько отличаться. Например, для Ubuntu 18.04 и выше 
установка будет выглядеть следующим образом:
```bash
sudo apt install qemu libvirt-clients bridge-utils lldpd python3-lxml qemu-kvm virtinst \
  pkg-config libvirt-dev libvirt-daemon-system libguestfs-tools python3-libvirt
sudo systemctl enable libvirtd
```

Далее следует добавить пользователя, от которого производится тестирование, в группу libvirt:
```bash
sudo usermod -aG $(cat /etc/passwd | cut -d: -f1 | grep libvirt) $(whoami)
```
и для предотвращения ошибки virt-customize: *cp: cannot open '/boot/vmlinuz-5.4.0-113-generic' for reading: 
Permission denied* следует дать доступ на чтение к текущему vmlinuz-образу для всех пользователей:
```bash
sudo chmod 644 /boot/$(ls /boot | grep "vmlinuz-$(uname -sr | awk '{print $2}')")
```
Все сценарии `kvm` настроены на копирование образов виртуальных машин в папку `/var/lib/libvirt/images/ansible`, поэтому 
нужно ее создать и дать права:
```bash
sudo mkdir /var/lib/libvirt/images/ansible
sudo chown $(whoami):$(whoami) /var/lib/libvirt/images/ansible
sudo chmod 775 /var/lib/libvirt/images/ansible
```
Удалять сеть по умолчанию (default NAT network) после установки KVM не нужно (она используется для тестирования),
в противном случае ее можно пересоздать из xml файла:
```xml
<network>
  <name>default</name>
  <forward mode="nat"/>
  <domain name="default"/>
  <ip address="192.168.175.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.175.128" end="192.168.175.254"/>
    </dhcp>
  </ip>
</network>
```
выполнив:
```bash
sudo virsh net-create <xml_file>
```

### Настройка окружения для default и kvm сценариев с помощью скриптов:

Установка окружения может быть произведена с помощью скрипта из папки [.scripts/](.scripts/):
```bash
./.scripts/setup_ansible_environment.sh -s kvm
```
для kvm сценария, или `-s default` - для default.

Опционально можно установить только лишь одни зависимости pip из requirements-файлов, например:
`python_x.x_<scenario_name>_requirments.txt`:
```bash
python3 -m pip install -r python_x.x_<scenario_name>_requirments.txt
```
Но, так как учесть все возможные нюансы настроек окружений, версий python, способов установки и путей в различных 
дистрибутивах, крайне сложно, то зачастую после того, как вы воспользуетесь как скриптом, или установкой одних 
лишь зависимостей pip (`-r requirements.txt`), вероятно, вам все равно придется разрешить проблемы с зависимостями 
вручную, как [описано выше](#установка-и-настройка-окружения-ansible-и-molecule-ansible).

## CI проекта

Gitlab CI данного репозитория включает в себя:

- **pre-check**: предварительная проверка CI скриптов ([shellcheck](https://www.shellcheck.net/) и т.д.).
- **lint_and_sanity: credentials check**: с целью безопасности проверяются все файлы inventory на предмет забытых
заполненных логинов и паролей.
- **lint_and_sanity: ansible-lint**: Проверка yaml и ansible синтаксиса всего проекта с помощью ansible-lint и yamllint.
Для его работы в корне проекта необходимо разместить файлы настроек `.ansible-lint` и `.yamllint`.
- **lint_and_sanity: ansible_test_sanity**: Проверка всех ansible Galaxy коллекций проекта (при merge request, или
push'е в ветку devel), или коллекций, в которые были внесены изменения с помощью
[ansible-test: sanity](https://docs.ansible.com/ansible/latest/dev_guide/testing_sanity.html).
- **lint_and_sanity: molecule test**: тестирование всех ролей (при merge request, или push'е в ветку devel), или ролей,
в которые были внесены изменения с помощью [ansible molecule](https://molecule.readthedocs.io/en/latest/index.html).
- **merge_to_master**: Инкремент версии ansible Galaxy коллекции (если были внесены изменения) и merge в ветку 'master'
(или 'main').

## Полезные ссылки:

- [Galaxy Developer Guide](https://docs.ansible.com/ansible/latest/galaxy/dev_guide.html)
- [alexanderbazhenoff.linux ansible collection](https://github.com/alexanderbazhenoff/ansible-collection-linux)
