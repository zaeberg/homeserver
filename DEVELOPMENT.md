# Development Guide

Этот документ описывает процесс внесения изменений в homeserver, от локального тестирования до деплоя на сервер.

## Введение

Homeserver — это infrastructure-as-code проект для развёртывания self-hosted сервера. Все изменения должны быть:
- Тестируемы локально (валидация конфигов)
- Обратимы (git history, backups)
- Документированы (обновление документации)

## Локальное тестирование

### Требования

```bash
# Docker + Docker Compose v2
docker --version
docker compose version

# Bash (для скриптов)
bash --version

# Опционально: yamllint для проверки YAML
sudo apt install yamllint
```

### Валидация конфигурации

**Без запуска контейнеров:**

```bash
# Проверка Docker Compose конфига
docker compose -f compose/compose.yml config

# Проверка YAML синтаксиса
yamllint compose/compose.yml
yamllint compose/traefik/*.yml

# Запуск скрипта валидации (проверяет файлы, секреты, права)
./scripts/validate.sh
```

**С запуском контейнеров (только для тестов):**

```bash
# Запустить стек в test mode
docker compose -f compose/compose.yml up -d

# Проверить status
docker compose -f compose/compose.yml ps

# Проверить логи
docker compose -f compose/compose.yml logs -f

# Остановить
docker compose -f compose/compose.yml down
```

### Предупреждение

⚠️ **НЕ запускайте весь стек на локальной машине**, если это не тест!
- Traefik может захватить порты 80/443
- Сервисы могут конфликтовать с существующими
- Скрипты деплоя/бэкапов предназначены для сервера

## Workflow внесения изменений

### 1. Создать branch

```bash
# Синхронизировать main branch
git checkout master
git pull origin master

# Создать feature branch
git checkout -b feature/add-nginx-service

# Или для bugfix
git checkout -b fix/traefik-routing
```

### 2. Внести изменения

```bash
# Например: добавить новый сервис в compose/compose.yml
nano compose/compose.yml

# Или: обновить документацию
nano docs/07_adding_services.md
```

### 3. Валидация

```bash
# Проверить конфигурацию
./scripts/validate.sh

# Проверить Docker Compose синтаксис
docker compose -f compose/compose.yml config

# Проверить изменения
git diff
```

### 4. Локальное тестирование (если применимо)

```bash
# Для изменений в compose/compose.yml:
# - Проверить, что YAML валиден
# - Проверить, что labels корректны
# - НЕ запускать, если не уверены

# Для изменений в скриптах:
./scripts/validate.sh  # Должен пройти без ошибок

# Для изменений в документации:
# - Проверить, что ссылки работают
# - Проверить, что примеры корректны
```

### 5. Commit

```bash
# Добавить изменения
git add compose/compose.yml
git add docs/07_adding_services.md

# Commit с понятным сообщением
git commit -m "feat: add Nginx service with Traefik routing

- Add nginx service to compose/compose.yml
- Configure Traefik labels for routing
- Add example to docs/07_adding_services.md
- Update README.md with new service

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

### 6. Push и pull request (если используете PRs)

```bash
# Push branch
git push origin feature/add-nginx-service

# Создать Pull Request (через GitHub/GitLab UI)
```

## Code Style

### Bash Scripts

**Shebang:**
```bash
#!/usr/bin/env bash
```

**Indentation:** 2 spaces

**Quotes:** всегда используйте double quotes для переменных
```bash
# ✅ Хорошо
echo "Path: ${PATH}"
docker compose -f "${COMPOSE_FILE}" up -d

# ❌ Плохо
echo Path: $PATH
```

**Error handling:**
```bash
# Всегда проверяйте exit codes
if ! docker compose up -d; then
    echo "Failed to start services"
    exit 1
fi

# Или set -e для немедленного выхода при ошибке
set -e
```

**Functions:**
```bash
log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}
```

### YAML (Docker Compose, Traefik)

**Indentation:** 2 spaces (НЕ tabs!)

**Comments:** используйте `#` для комментариев
```yaml
# Это комментарий
services:
  nginx:
    image: nginx:latest  # Inline комментарий
```

**Quotes:** используйте double quotes для строк со специальными символами
```yaml
# ✅ Хорошо
labels:
  - "traefik.enable=true"

# ❌ Плохо (без кавычек, если есть спецсимволы)
labels:
  - traefik.enable=true  # Может не работать
```

**Многострочные команды:**
```yaml
# ✅ Хорошо
command: >
  bash -c "
    echo 'Hello'
    echo 'World'
  "

# ❌ Плохо (однострочная, нечитаемая)
command: bash -c "echo 'Hello'; echo 'World'"
```

### Markdown (Документация)

**Headers:**
```markdown
# H1 - только один в начале файла
## H2 - основные секции
### H3 - подсекции
```

**Code blocks:**
```markdown
# Inline code
Используйте `docker compose up` для запуска.

# Code block с языком
```bash
docker compose up -d
```

# Code block без подсветки
```
docker compose up -d
```
```

**Links:**
```markdown
[Текст ссылки](path/to/file.md)
[Внешняя ссылка](https://example.com)
```

## Pre-commit Checklist

Перед commit проверьте:

- [ ] Конфигурация валидна (`./scripts/validate.sh`)
- [ ] Docker Compose config проходит (`docker compose config`)
- [ ] Нет секретов в изменениях (grep для PASSWORD, SECRET, etc.)
- [ ] Документация обновлена (если изменился API/конфигурация)
- [ ] Links в документации работают
- [ ] Commit message следует конвенции (см. ниже)
- [ ] Изменения тестируемы (или описано, как тестировать)

## Commit Message Convention

Используйте Conventional Commits:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` — новая функциональность
- `fix` — bug fix
- `docs` — изменения в документации
- `style` — форматирование (не меняющее поведение)
- `refactor` — рефакторинг
- `test` — добавление тестов
- `chore` — рутинные задачи (update dependencies, etc.)

**Examples:**

```bash
# Простая фича
git commit -m "feat: add whoami test service"

# Bug fix
git commit -m "fix: correct Traefik network configuration"

# Документация
git commit -m "docs: add architecture overview"

# Breaking change
git commit -m "feat!: change Traefik v2 to v3

BREAKING CHANGE: Traefik v3 has different syntax.
See migration guide: https://doc.traefik.io/traefik/v3.6/"
```

## Тестирование на сервере

### Подготовка

```bash
# 1. Сделать backup текущего состояния (если критичные изменения)
./scripts/backup.sh

# 2. Синхронизировать код с сервером
cd /srv/homelab/homelab-server
git pull origin master

# Или rsync с локальной машины:
rsync -av --exclude='.git' \
  /home/zaeberg/Documents/projects/homeserver/ \
  user@homeserver:/srv/homelab/homelab-server/
```

### Деплой

```bash
# Валидация на сервере
./scripts/validate.sh

# Деплой (перезапустит все сервисы!)
./scripts/deploy.sh

# Или для конкретного сервиса
docker compose -f compose/compose.yml up -d nginx
```

### Проверка после деплоя

```bash
# Проверить status контейнеров
docker ps

# Проверить логи
docker logs homelab-traefik -f

# Проверить healthcheck
docker inspect --format='{{.State.Health.Status}}' homelab-traefik

# Проверить доступность сервисов
curl -I http://traefik.home.local/dashboard/
```

### Rollback

```bash
# Если что-то пошло не так
git log --oneline  # Найти последний рабочий commit
git revert HEAD   # Отменить последний commit
git push origin master

# Или откатиться до конкретного commit
git reset --hard <commit-hash>
git push -f origin master  # ОСТОРОЖНО!

# На сервере:
cd /srv/homelab/homelab-server
git pull origin master
./scripts/deploy.sh
```

## Troubleshooting разработки

### `docker compose config` fails

**Проблема:** Синтаксическая ошибка в YAML

**Решение:**
```bash
# Проверить YAML синтаксис
yamllint compose/compose.yml

# Найти ошибку (обычно indentation)
docker compose -f compose/compose.yml config | less
```

### Скрипт не запускается

**Проблема:** Permission denied

**Решение:**
```bash
chmod +x scripts/*.sh
```

### Traefik не видит сервис

**Проблема:** Неправильные labels

**Решение:**
```bash
# Проверить labels контейнера
docker inspect homelab-myservice | grep -A 20 Labels

# Проверить логи Traefik
docker logs homelab-traefik | grep myservice
```

### Secrets в git history

**Проблема:** Случайно закоммитили секреты

**Решение:**
```bash
# 1. Удалить секрет из файла
git checkout HEAD~1 -- compose/.env

# 2. Добавить в .gitignore (если ещё нет)
echo "compose/.env" >> .gitignore

# 3. Переписать историю (ОСТОРОЖНО!)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch compose/.env" \
  --prune-empty --tag-name-filter cat -- --all

# 4. Force push
git push -f origin master
```

**Лучшая практика:** Используйте `git-secrets` для предотвращения:
```bash
git secrets --install
git secrets --add 'PASSWORD.*='
git secrets --add 'SECRET.*='
```

## Дальнейшее чтение

- `docs/00_architecture.md` — архитектура системы
- `docs/07_adding_services.md` — добавление сервисов
- `docs/05_operations.md` — операции на сервере
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
