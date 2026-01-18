# Обновление документации после миграции на Traefik

**Status**: `complete`

## Problem Statement

Обновить всю документацию и README после замены Caddy на Traefik v3.6.7. Заменить все упоминания Caddy на Traefik, обновить инструкции по настройке, деплою и операциям обслуживания. Удалить устаревшие ссылки на Caddyfile и Caddy-специфичные команды.

## Problem Analysis

**Почему это нужно сделать:**
1. **Актуальность документации** — Документация должна соответствовать текущей инфраструктуре (Traefik, а не Caddy)
2. **Избежание путаницы** — Пользователи не должны видеть устаревшие инструкции по Caddy
3. **Корректность примеров** — Все команды должны работать с Traefik (например, `docker exec homelab-traefik` вместо `homelab-caddy`)

**Что конкретно делаем:**
- Заменяем все упоминания "Caddy" → "Traefik" в документации
- Обновляем структуру директорий (caddy/ → traefik/)
- Заменяем Caddyfile → traefik.yml + dynamic.yml
- Обновляем команды валидации (`caddy validate` → проверка traefik.yml)
- Обновляем команды логов (`docker compose logs caddy` → `docker compose logs traefik`)
- Меняем пути создания директорий `/srv/data/caddy` → `/srv/data/traefik`
- Обновляем список сервисов в README

**Найденные файлы для обновления:**

| Файл | Тип изменений |
|------|---------------|
| `README.md` | Список сервисов: Caddy → Traefik |
| `docs/01_repo_overview.md` | Структура директорий, описание сервиса |
| `docs/03_deploy.md` | Создание директорий, валидация Caddyfile |
| `docs/05_operations.md` | Команды управления, редактирование конфига |
| `docs/06_troubleshooting.md` | Решение проблем, логи, валидация |
| `docs/02_server_bootstrap.md` | mkdir команды, примеры вывода |
| `docs/04_backup_restore.md` | mkdir команды |
| `scripts/validate.sh` | Проверка Caddyfile (если есть) |

## Questions Resolved
- Q: Нужно ли удалять compose/caddy/ директорию?
  A: Нет, это будет сделано отдельно в задаче по cleanup. Только обновляем документацию.
- Q: Что делать с планом `homelab-repo-setup.plan.md` который упоминает Caddy?
  A: Это исторический план, его можно не трогать или добавить заметку о миграции.
- Q: Обновлять ли `todo.md`?
  A: Да, удалить проблемы связанные с Caddy (проблемы #1, #12, #22, частично #25).

## Edge Cases & Considerations
- [ ] **Версия Traefik** — Указываем v3.6.7 везде, где упоминается версия
- [ ] **Названия контейнеров** — `homelab-caddy` → `homelab-traefik` во всех командах
- [ ] **Конфигурационные файлы** — Caddyfile → traefik.yml + dynamic.yml
- [ ] **Порты** — Caddy использовал только 80, Traefik использует 80 + 443 + 8080
- [ ] **Dashboard** — Traefik имеет dashboard на порту 8080 (отсутствовал у Caddy)
- [ ] **Basic Auth** — Traefik использует другой формат basic auth в labels
- [ ] **Команды валидации** — `caddy validate --config` → визуальная проверка traefik.yml
- [ ] **Скрипты** — Проверить `scripts/validate.sh` на предмет проверки Caddyfile

## Relevant Context
- `README.md` — Основной файл с описанием сервисов (строка 11: Caddy)
- `docs/01_repo_overview.md` — Обзор репозитория, структура директорий (строки 11, 62, 76)
- `docs/03_deploy.md` — Инструкция деплоя (строки 72, 90: mkdir, валидация)
- `docs/05_operations.md` — Операции обслуживания (строки 279-285: команды caddy)
- `docs/06_troubleshooting.md` — Решение проблем (строки 61, 296, 309, 312, 315: логи, валидация)
- `docs/02_server_bootstrap.md` — Bootstrap ОС (строки 264, 495, 503: mkdir, примеры)
- `docs/04_backup_restore.md` — Бэкап и восстановление (строка 232: mkdir)
- `scripts/validate.sh` — Скрипт валидации (возможная проверка Caddyfile)
- `plans/todo.md` — Список проблем (проблемы #1, #12, #22, #25 связаны с Caddy)
- `compose/compose.yml` — Новый compose с Traefik (для референса)
- `compose/traefik/traefik.yml` — Конфиг Traefik (для референса)
- `compose/traefik/dynamic.yml` — Динамический конфиг (для референса)

## Feature Steps

- [ ] **Обновление README.md**
  - **Business Value**: Пользователи видят актуальный список сервисов с Traefik вместо Caddy
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] В разделе "Сервисы" заменено: "**Caddy** — reverse proxy" → "**Traefik** — reverse proxy с автоматическим HTTPS"
    - [ ] Обновлено описание: добавлена информация о Docker auto-discovery
    - [ ] Версия указана как v3.6.7 (если упоминается)
    - [ ] Нет упоминаний Caddy в тексте
  - **Touches**: `README.md`

- [ ] **Обновление docs/01_repo_overview.md**
  - **Business Value**: Структура репозитория соответствует текущей (traefik/ вместо caddy/)
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] В структуре директорий заменено: `├── caddy/` → `├── traefik/`
    - [ ] В описании данных заменено: `/srv/data/caddy` → `/srv/data/traefik`
    - [ ] В разделе файлов заменены все упоминания Caddy → Traefik
    - [ ] Описание Traefik включает traefik.yml и dynamic.yml
  - **Touches**: `docs/01_repo_overview.md`

- [ ] **Обновление docs/03_deploy.md**
  - **Business Value**: Инструкция деплоя создаёт правильные директории и проверяет правильные файлы
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] В команде mkdir заменено: `vaultwarden,syncthing,filebrowser,uptime-kuma,caddy` → `traefik` (или просто `traefik`, так как другие сервисы удалены)
    - [ ] В валидации заменено: `✓ File exists: caddy/Caddyfile` → `✓ Files exist: traefik/traefik.yml, traefik/dynamic.yml`
    - [ ] Нет упоминаний Caddyfile или Caddy в командах
  - **Touches**: `docs/03_deploy.md`

- [ ] **Обновление docs/05_operations.md**
  - **Business Value**: Пользователи имеют корректные команды для управления Traefik
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Раздел "Редактирование reverse proxy конфига" обновлён для Traefik
    - [ ] Команда заменена: `nano caddy/Caddyfile` → `nano traefik/traefik.yml` или `nano traefik/dynamic.yml`
    - [ ] Перезапуск обновлён: `restart caddy` → `restart traefik`
    - [ ] Валидация обновлена: `docker exec homelab-caddy caddy validate...` → описание визуальной проверки или команды traefik
    - [ ] Нет упоминаний Caddy или Caddyfile в операциях
  - **Touches**: `docs/05_operations.md`

- [ ] **Обновление docs/06_troubleshooting.md**
  - **Business Value**: Решение проблем работает с Traefik вместо Caddy
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Все команды `docker compose logs caddy` заменены на `docker compose logs traefik`
    - [ ] Все команды `docker exec homelab-caddy` заменены на `docker exec homelab-traefik` (или удалены, если не применимы)
    - [ ] Команды валидации обновлены или удалены (если специфичны для Caddy)
    - [ ] Нет упоминаний Caddy в решениях проблем
  - **Touches**: `docs/06_troubleshooting.md`

- [ ] **Обновление docs/02_server_bootstrap.md и docs/04_backup_restore.md**
  - **Business Value**: Примеры команд создают правильные директории (/srv/data/traefik вместо /srv/data/caddy)
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] В `02_server_bootstrap.md` заменены все mkdir команды: `...,caddy,...` → `...,traefik,...` (или только `traefik`)
    - [ ] В `02_server_bootstrap.md` обновлены примеры вывода (если есть упоминания `homelab-caddy`)
    - [ ] В `04_backup_restore.md` заменена mkdir команда: `...,caddy,...` → `traefik`
    - [ ] Нет устаревших упоминаний Caddy в примерах
  - **Touches**: `docs/02_server_bootstrap.md`, `docs/04_backup_restore.md`

- [ ] **Обновление plans/todo.md**
  - **Business Value**: Список проблем не содержит устаревших проблем, связанных с Caddy
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Проблема #1 (Отсутствие HTTPS) — обновлена или удалена (Traefik уже поддерживает HTTPS)
    - [ ] Проблема #12 (Caddy хранит данные в /srv/data/caddy) — удалена или обновлена для Traefik
    - [ ] Проблема #22 (Caddy healthcheck невалиден) — удалена (Traefik healthcheck корректен)
    - [ ] Проблема #25 (Невозможность работы без интернета) — обновлена, если относится к Let's Encrypt
    - [ ] Нет упоминаний Caddyfile или специфичных Caddy проблем
  - **Touches**: `plans/todo.md`

- [ ] **Проверка и обновление scripts/validate.sh**
  - **Business Value**: Скрипт валидации не проверяет несуществующий Caddyfile
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Скрипт проверен на наличие проверок Caddyfile
    - [ ] Если есть проверки Caddyfile — заменены на проверки traefik.yml/dynamic.yml или удалены
    - [ ] Скрипт работает корректно с текущей структурой (traefik/ вместо caddy/)
  - **Touches**: `scripts/validate.sh`

## Testing Strategy

**Как проверяем корректность обновления:**
1. ✅ Визуальная проверка — grep поиска не находит "Caddy" или "caddy" в обновлённых файлах (кроме планов и исторических справок)
2. ✅ Проверка имён файлов — все упоминания `caddy/Caddyfile` заменены на `traefik/traefik.yml`
3. ✅ Проверка команд — все `docker exec homelab-caddy` заменены на `homelab-traefik`
4. ✅ Проверка путей — все `/srv/data/caddy` заменены на `/srv/data/traefik`
5. ✅ Проверка версий — Traefik v3.6.7 указан корректно

**Исключения:**
- Планы в `plans/` можно не обновлять (это исторические справки)
- Git история остаётся без изменений

## Notes
