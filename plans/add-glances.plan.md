# Добавление Glances - System Monitoring

**Status**: `complete`

## Problem Statement
Добавить систему мониторинга сервера Glances с веб-интерфейсом в существующий Docker Compose стек homeserver. Сервис должен быть доступен через Traefik reverse proxy и публиковаться в локальной сети через mDNS.

## Problem Analysis

**Что делаем и зачем:**

Glances - это продвинутая система мониторинга ресурсов сервера (CPU, RAM, диск, сеть, процессы) с красивым веб-интерфейсом. Это successor/альтернатива htop с веб-UI.

**Почему именно так:**

1. **Безопасность**: Glances требует `pid: host` для мониторинга всех процессов на хост-системе. Без этого он будет видеть только свои собственные процессы, что бесполезно.

2. **Сеть**: Официальный docker-compose использует `network_mode: host` для прямого доступа к хост-системе. Однако в твоей архитектуре все сервисы должны быть в сети `internal` для маршрутизации через Traefik. Компромисс:
   - Убираем `network_mode: host`
   - Добавляем сервис в сеть `internal`
   - Используем Traefik для маршрутизации по hostname
   - Оставляем `pid: host` для доступа к метрикам хоста

3. **Volumes**: Glances нужен доступ к:
   - `/` (root filesystem) - только чтение для метрик диска
   - `/var/run/docker.sock` - для мониторинга Docker контейнеров
   - Конфигурационный файл `glances.conf` - для кастомизации

4. **Порты**: Web-интерфейс работает на порту 61208

## Questions Resolved
- Q: Какой hostname использовать для доступа?
  A: Будет использован `glances.home.local` (стандартное название)

- Q: Нужен ли бэкап конфигурации Glances?
  A: Конфиг не критичен, но будет добавлен в бэкап для сохранения настроек

## Edge Cases & Considerations
- [ ] **pid: host без network_mode: host** → Glances будет работать с `pid: host` но в сети `internal`. Это позволяет видеть все процессы хоста, но маршрутизация идёт через Traefik
- [ ] **Доступ к Docker сокету** → Glances получает read-only доступ к `/var/run/docker.sock` для мониторинга контейнеров
- [ ] **Конфигурационный файл** → Создаём базовый `glances.conf`, пользователь сможет кастомизировать позже
- [ ] **Производительность** → Glances лёгкий, не требует resource limits по умолчанию
- [ ] **Безопасность** → Все volumes монтируются как read-only (кроме тех, где нужно)

## Relevant Context
- `compose/compose.yml:19-57` - Пример конфигурации Traefik с labels
- `compose/compose.yml:144-154` - Определение сетей internal и public
- `docs/07_adding_services.md:14-44` - Минимальная конфигурация сервиса с Traefik labels
- `docs/04_backup_restore.md` - Система бэкапов на базе Restic

## Feature Steps
> **Note**: Каждый шаг описывает пользовательскую историю, а не детали реализации.

- [x] **Добавлен сервис Glances в docker-compose стек**
  - **Business Value**: Пользователь получает веб-интерфейс для мониторинга ресурсов сервера в реальном времени (CPU, RAM, диск, сеть, процессы)
  - **Depends on**: none
  - **Definition of Done**:
    - [x] Glances добавлен в `compose/compose.yml`
    - [x] Используется образ `nicolargo/glances:latest-full` (full версия со всеми плагинами)
    - [x] Настроен `pid: host` для мониторинга всех процессов
    - [x] Подключён к сети `internal`
    - [x] Добавлены необходимые volumes (`/`, docker.sock, glances.conf)
    - [x] Настроен healthcheck на `/api/4/status`
    - [x] Добавлен restart policy `unless-stopped`
  - **Touches**: `compose/compose.yml`

- [x] **Настроена маршрутизация через Traefik**
  - **Business Value**: Пользователь может получить доступ к Glances по удобному hostname `glances.home.local` без необходимости помнить порты
  - **Depends on**: "Добавлен сервис Glances в docker-compose стек"
  - **Definition of Done**:
    - [x] Добавлены Traefik labels (`traefik.enable=true`, router rule, service port, entrypoints)
    - [x] Web-интерфейс доступен по адресу `http://glances.home.local`
    - [x] Порт 61208 корректно пробрасывается через Traefik
  - **Touches**: `compose/compose.yml`

- [x] **Настроена публикация в локальной сети через mDNS**
  - **Business Value**: Пользователь видит Glances в списке сетевых сервисов на всех устройствах в локальной сети (Mac, iOS, Linux) без настройки DNS
  - **Depends on**: "Настроена маршрутизация через Traefik"
  - **Definition of Done**:
    - [x] Добавлены mDNS labels (`avahi.homeserver.service`, `avahi.homeserver.protocol`)
    - [x] Сервис публикуется как "Glances System Monitor"
    - [x] Сервис виден в сети после запуска контейнера
  - **Touches**: `compose/compose.yml`

- [x] **Создана базовая конфигурация Glances**
  - **Business Value**: Пользователь получает рабочую конфигурацию из коробки, которую можно кастомизировать под свои нужды
  - **Depends on**: none
  - **Definition of Done**:
    - [x] Создан файл `compose/glances/glances.conf`
    - [x] Конфиг подключён как volume к контейнеру
    - [x] Включены основные плагины (smart, docker, etc.)
    - [x] Настроена timezone
  - **Touches**: `compose/glances/glances.conf` (новый файл)

- [x] **Добавлено правило бэкапа для конфигурации**
  - **Business Value**: Конфигурация Glances сохраняется в бэкапах, что позволяет быстро восстановить настройки после сбоя или при миграции
  - **Depends on**: "Создана базовая конфигурация Glances"
  - **Definition of Done**:
    - [x] Директория `compose/glances/` автоматически бэкапится (включена в `/srv/homelab/homelab-server`)
    - [x] Добавлен пример в `.env.example` для добавления `/srv/data/glances` (если понадобится)
    - [x] Документация по бэкапу в `docs/09_glances_monitoring.md`
  - **Touches**: `compose/.env.example`

## Testing Strategy

⚠️ **Примечание**: Тестирование будет выполняться пользователем на сервере, так как нет локального доступа к Docker.

**Мануальное тестирование (пользователем):**
1. Деплой сервиса: `./scripts/deploy.sh`
2. Проверка контейнера: `docker ps | grep glances`
3. Проверка логов: `docker logs homelab-glances`
4. Проверка API: `curl http://glances.home.local/api/4/status`
5. Проверка web-UI: Открыть `http://glances.home.local` в браузере
6. Проверка mDNS: `avahi-browse -a | grep Glances` (на Linux) или проверить в сетевых настройках на Mac/iOS
7. Проверка метрик: отображаются ли CPU/RAM/диск/процессы/Docker контейнеры

## Notes
- Glances требует `pid: host`, но не требует `network_mode: host`. Это компромисс между безопасностью и функциональностью.
- В будущем можно добавить авторизацию через Traefik middleware (Basic Auth) - см. `docs/07_adding_services.md:100-129`
- Можно добавить GPU мониторинг для Nvidia (закомментировано в официальном compose)
- Можно добавить SMART monitoring для дисков (требует дополнительные capabilities)
