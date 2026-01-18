# Улучшение документации Homeserver

**Status**: `complete`

## Problem Statement
Текущая документация отлично покрывает базовые сценарии использования (bootstrap, deploy, operations, troubleshooting), но имеет существенные пробелы для понимания архитектуры, развития проекта и внесения изменений. Новым контрибьюторам и даже самому автору спустя время сложно:
- Понять, как компоненты системы взаимодействуют друг с другом
- Добавить новые сервисы через Traefik
- Обеспечить безопасность конфигурации
- Вносить изменения с пониманием полного контекста

## Problem Analysis

**Почему это важно:**
- **Архитектурный обзор** необходим для понимания "big picture" — как Traefik, traefik-avahi-helper, сети и сервисы образуют единую систему
- **Guide по добавлению сервисов** критичен, так как это основная операция при развитии homeserver'а
- **Security guidelines** обязательны для любого server-проекта, особенно exposed к интернету
- **Development workflow** нужен для последовательного внесения изменений без breaking changes
- **Комментарии в конфигах** экономят время при возвращении к коду спустя месяцы

**Что будет улучшено:**
- Понимание системы новыми пользователями/контрибьюторами
- Скорость добавления новых сервисов
- Безопасность конфигурации
- Поддерживаемость проекта в долгосрочной перспективе

## Questions Resolved
Нет вопросов — задача чётко определена по результатам анализа кода.

## Edge Cases & Considerations

- [ ] **Diagrams могут устаревать** → Будем использовать текстовые ASCII diagrams для простого обновления
- [ ] **Traefik версии 3.6+** → Документация должна соответствовать версии Traefik v3 (синтаксис изменился с v2)
- [ ] **Разные сценарии использования** → Учитывать как local-only (без интернета), так и internet-exposed deployments
- [ ] **Уровень подготовки читателя** → Рассчитывать на intermediate Linux/Docker пользователя, beginner concepts объяснять кратко

## Relevant Context

### Существующая документация:
- `README.md` - Обзор проекта и быстрый старт
- `docs/01_repo_overview.md` - Структура репозитория
- `docs/02_server_bootstrap.md` - Установка Ubuntu Server + Docker
- `docs/03_deploy.md` - Деплой на сервер
- `docs/04_backup_restore.md` - Restic бэкапы
- `docs/05_operations.md` - Операции: обновление, логи, мониторинг
- `docs/06_troubleshooting.md` - Диагностика проблем

### Конфигурационные файлы (требуют комментариев):
- `compose/compose.yml:1-100` - Основной стек сервисов
- `compose/traefik/traefik.yml:1-50` - Статическая конфигурация Traefik
- `compose/traefik/dynamic.yml:1-50` - Динамическая конфигурация (routers, middlewares, services)

### Скрипты (требуют README):
- `scripts/deploy.sh` - Деплой сервисов
- `scripts/validate.sh` - Валидация конфигов
- `scripts/healthcheck.sh` - Проверка работоспособности
- `scripts/backup.sh` - Бэкапы через Restic
- `scripts/restore_test.sh` - Тест восстановления

### Systemd units (требуют README):
- `systemd/homelab-backup-local.{service,timer}` - Локальные бэкапы
- `systemd/homelab-backup-cloud.{service,timer}` - Облачные бэкапы
- `systemd/homelab-restore-test.service` - Еженедельные тесты restore

## Feature Steps

- [ ] **Архитектурный overview с diagram'ами**
  - **Business Value**: Позволяет быстро понять, как компоненты системы взаимодействуют, без чтения всех конфигов
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Создан `docs/00_architecture.md` с ASCII diagram'ами
    - [ ] Описаны все основные компоненты: Traefik, traefik-avahi-helper, Restic, systemd timers
    - [ ] Показан поток запроса от клиента к сервису
    - [ ] Описаны сети (internal vs public) и их назначение
    - [ ] Объяснена работа mDNS/Bonjour для `.home.local`
    - [ ] Добавлена ссылка на новый файл в README.md
  - **Touches**: `docs/00_architecture.md`, `README.md`

- [ ] **Guide по добавлению новых сервисов**
  - **Business Value**: Ускоряет добавление новых сервисов, eliminates trial-and-error с Traefik labels
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Создан `docs/07_adding_services.md`
    - [ ] Описаны требования к сервису (Docker image, networks, volumes)
    - [ ] Приведён полный пример добавления сервиса (например, Nginx или Whoami)
    - [ ] Описаны все необходимые Traefik labels (Router, Middleware, Service)
    - [ ] Показаны примеры: с HTTPS, с Basic Auth, с rate limiting
    - [ ] Добавлен troubleshooting раздел для типичных проблем
    - [ ] Добавлена ссылка на новый файл в README.md
  - **Touches**: `docs/07_adding_services.md`, `README.md`

- [ ] **Security best practices guide**
  - **Business Value**: Повышает безопасность сервера, предотвращает типичные уязвимости
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Создан `docs/08_security.md`
    - [ ] Описано управление секретами (хранение .env, rotation, password manager)
    - [ ] Описана настройка Basic Auth для Traefik dashboard
    - [ ] Добавлены firewall правила (UFW примеры)
    - [ ] Описана настройка HTTPS с Let's Encrypt
    - [ ] Добавлены рекомендации по ограничению доступа к dashboard
    - [ ] Описаны best practices для Docker security
    - [ ] Добавлена ссылка на новый файл в README.md
  - **Touches**: `docs/08_security.md`, `compose/traefik/dynamic.yml`, `README.md`

- [ ] **Добавление комментариев в compose.yml**
  - **Business Value**: Делает конфиг понятным без чтения документации
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Добавлены комментарии к каждому сервису (Traefik, traefik-avahi-helper)
    - [ ] Описаны все volumes и их назначение
    - [ ] Описаны networks (internal vs public)
    - [ ] Описаны critical Traefik labels
    - [ ] Комментарии на русском языке (согласно CLAUDE.md)
  - **Touches**: `compose/compose.yml`

- [ ] **Добавление комментариев в traefik.yml (статическая конфигурация)**
  - **Business Value**: Объясняет базовую настройку Traefik
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Прокомментирована каждая секция (entryPoints, providers, api)
    - [ ] Объяснено, зачем `insecure: true` и когда его убрать
    - [ ] Описаны параметры providers.docker
    - [ ] Добавлены ссылки на официальную документацию Traefik v3
  - **Touches**: `compose/traefik/traefik.yml`

- [ ] **Добавление комментариев в dynamic.yml (динамическая конфигурация)**
  - **Business Value**: Объясняет middlewares, routers, services
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Прокомментирован каждый middleware
    - [ ] Описана настройка Basic Auth (закомментирована с инструкцией)
    - [ ] Добавлены примеры добавления новых routers
    - [ ] Описана настройка HTTPS для Traefik dashboard (закомментирована)
  - **Touches**: `compose/traefik/dynamic.yml`

- [ ] **Development workflow guide**
  - **Business Value**: Стандартизирует процесс внесения изменений, уменьшает количество ошибок
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Создан `DEVELOPMENT.md`
    - [ ] Описан процесс локального тестирования (если применимо)
    - [ ] Описан workflow: create branch → changes → validate → test → commit
    - [ ] Добавлен раздел code style (Bash, YAML)
    - [ ] Описан pre-commit checklist
    - [ ] Добавлена ссылка на новый файл в README.md
  - **Touches**: `DEVELOPMENT.md`, `README.md`

- [ ] **README для скриптов автоматизации**
  - **Business Value**: Объясняет назначение и требования каждого скрипта
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Создан `scripts/README.md`
    - [ ] Описаны требования (docker, restic, jq, curl)
    - [ ] Описан каждый скрипт: назначение, использование, параметры
    - [ ] Добавлены примеры запуска
    - [ ] Описаны exit codes и обработка ошибок
  - **Touches**: `scripts/README.md`

- [ ] **README для systemd units**
  - **Business Value**: Объясняет автоматизацию бэкапов и параметры таймеров
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Создан `systemd/README.md`
    - [ ] Описаны все timer units и их расписание
    - [ ] Объяснены параметры `Nice=10` и `IOSchedulingClass=idle`
    - [ ] Добавлены инструкции по изменению расписания
    - [ ] Описана procedure enable/disable timers
    - [ ] Добавлены примеры кастомных расписаний
  - **Touches**: `systemd/README.md`

- [ ] **Улучшение .env.example с описанием переменных**
  - **Business Value**: Делает понятным, какие переменные обязательные и что они означают
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Каждая переменная прокомментирована
    - [ ] Указано, какие переменные обязательные, какие опциональные
    - [ ] Описаны значения по умолчанию
    - [ ] Добавлены секции для логической группировки
    - [ ] Добавлены warnings для критичных переменных (RESTIC_PASSWORD)
  - **Touches**: `compose/.env.example`

## Testing Strategy

**Как проверять:**
- **README файлы**: Читаются без разбоя, следуют логической структуре
- **Комментарии в конфигах**: YAML валиден (проверять через `docker compose config`)
- **Новые docs**: Ссылки в README.md ведут на существующие файлы
- **Примеры кода**: Копируются и работают без модификации (валидация YAML)

**Manual testing:**
```bash
# Проверка YAML конфигов после добавления комментариев
docker compose -f compose/compose.yml config

# Проверка ссылок в README
grep -E '\[.*\]\(docs/.*\)' README.md

# Проверка, что все новые файлы созданы
ls -la docs/00_architecture.md docs/07_adding_services.md docs/08_security.md
```

## Notes

- Порядок выполнения шагов не критичен, можно делать параллельно
- Комментарии в YAML должны использовать `#`, не breaking для docker-compose
- Все README файлы на русском языке (согласно CLAUDE.md)
- ASCII diagrams предпочтительнее изображений для простого обновления
