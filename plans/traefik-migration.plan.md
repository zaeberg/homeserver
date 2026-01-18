# Миграция с Caddy на Traefik

**Status**: `complete`

## Problem Statement
Заменить reverse proxy с Caddy на Traefik в Docker Compose конфигурации, удалив все остальные сервисы (Vaultwarden, Syncthing, Filebrowser, Uptime Kuma) из `compose/compose.yml`. Оставить только Traefik как единственный сервис. **Только подготовка конфигов и документации — запуск и тестирование выполняется пользователем на удалённом сервере.**

## Problem Analysis

**Почему это нужно сделать:**
1. **Traefik более функционален** — встроенная поддержка Docker auto-discovery, лучше подходит для микросервисной архитектуры
2. **Подготовка к будущим сервисам** — Traefik автоматически будет обнаруживать новые сервисы через Docker labels без изменения конфига
3. **Упрощение текущей инфраструктуры** — начнём с чистого листа, только reverse proxy, остальные сервисы добавим позже по одному

**Что конкретно делаем:**
- Откатываем текущие изменения в `compose/compose.yml` и `compose/.env.example` к состоянию до миграции
- Заменяем сервис `caddy` на `traefik` в compose.yml
- Удаляем все другие сервисы (vaultwarden, syncthing, filebrowser, uptime-kuma)
- Используем существующие Traefik конфиги в `compose/traefik/` как основу
- Обновляем `.env.example` — удаляем переменные удалённых сервисов
- Подготавливаем документацию для следующей задачи (будет обновлена отдельно)

**Контекст:**
- В `compose/traefik/` уже есть подготовленные конфиги (traefik.yml, dynamic.yml)
- Traefik будет слушать порты 80 (HTTP) и 443 (HTTPS)
- Dashboard будет доступен только через Basic Auth на `traefik.home.local`
- Используем Docker provider для автообнаружения будущих сервисов

## Questions Resolved
- Q: Нужно ли тестировать запуск контейнеров?
  A: **НЕТ** — только подготовка конфигов. Запуск и тестирование выполняется пользователем на сервере.
- Q: Использовать существующие traefik.yml и dynamic.yml как основу?
  A: Да, они уже подготовлены и готовы к использованию.
- Q: Что делать с compose/caddy/ директорией?
  A: Оставить для сейчас, будет удалена позже при cleanup.

## Edge Cases & Considerations
- [ ] **Traefik требует доступ к Docker socket** → Монтируем `/var/run/docker.sock` read-only
- [ ] **Let's Encrypt сертификаты** → Пока отключены в traefik.yml, будут добавлены позже
- [ ] **Basic Auth для dashboard** → Используем test credentials из traefik.yml, пользователь изменит на продакшене
- [ ] **Сети internal и public** → Traefik должен быть в обеих сетях для маршрутизации
- [ ] **Healthcheck Traefik** → Используем `traefik healthcheck --ping` вместо валидации конфига
- [ ] **Данные Traefik (certificates)** → Создаём `/srv/data/traefik/letsencrypt` для будущих SSL сертификатов
- [ ] **Валидация конфига без запуска** → Используем `docker compose config` для проверки синтаксиса (не запускает контейнеры)

## Relevant Context
- `compose/compose.yml` — Текущий Docker Compose файл с Caddy и 4 сервисами (до изменений)
- `compose/.env.example` — Шаблон переменных окружения с секретами сервисов (до изменений)
- `compose/caddy/Caddyfile` — Текущий Caddy конфиг (будет не нужен, но оставляем для сейчас)
- `compose/traefik/traefik.yml` — Новый Traefik статический конфиг (готов к использованию)
- `compose/traefik/dynamic.yml` — Traefik динамический конфиг с middlewares (готов к использованию)
- `docs/03_deploy.md` — Инструкция деплоя (ссылается на Caddy, будет обновлена в следующей задаче)
- `docs/05_operations.md` — Операции обслуживания (упоминает Caddy)
- `docs/01_repo_overview.md` — Обзор репозитория (перечисляет Caddy)

## Feature Steps

- [x] **Очистка репозитория и замена Caddy на Traefik в compose.yml**
  - **Business Value**: Получаем чистый Docker Compose только с Traefik, готовый для добавления сервисов через Docker labels
  - **Depends on**: none
  - **Definition of Done**:
    - [x] `compose/compose.yml` содержит только сервис `traefik` (без vaultwarden, syncthing, filebrowser, uptime-kuma)
    - [x] Сервис `caddy` полностью заменён на `traefik` с корректной конфигурацией
    - [x] Traefik монтирует `traefik.yml` и `dynamic.yml` из `compose/traefik/`
    - [x] Traefik имеет доступ к Docker socket (`/var/run/docker.sock:ro`)
    - [x] Порты 80, 443, 8080 проброшены корректно
    - [x] Traefik находится в сетях `internal` и `public`
    - [x] Healthcheck использует `traefik healthcheck --ping`
    - [x] Volume для `/srv/data/traefik/letsencrypt` добавлен (для будущих SSL сертификатов)
    - [x] `compose/.env.example` обновлён (удалены переменные удалённых сервисов, BASE_URL упрощён)
    - [x] Git показывает только ожидаемые изменения (compose/compose.yml, .env.example, traefik/)
  - **Touches**: `compose/compose.yml`, `compose/.env.example`

## Testing Strategy

**ВАЖНО**: Этот план ТОЛЬКО для подготовки конфигов. Вся валидация, запуск и тестирование выполняется пользователем на удалённом сервере.

**Что делаем в рамках этого плана:**
1. ✅ Подготовка всех конфигов (compose.yml, .env.example, traefik/*.yml)
2. ✅ Визуальное ревью файлов на корректность и полноту
3. ✅ Проверка, что git clean (нет неожиданных modified файлов)

**Что НЕ делаем в этом плане:**
- ❌ Не запускаем `docker compose config` или другие docker команды
- ❌ Не запускаем `docker compose up`
- ❌ Не проверяем работу контейнеров
- ❌ Не тестируем доступность сервисов

Всё вышеуказанное будет выполнено пользователем на сервере.

## Notes
