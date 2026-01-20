# Перенос конфигов Homepage в репозиторий

**Status**: `complete`

## Problem Statement
Текущая установка Homepage подразумевает ручное редактирование конфигов на удаленном сервере в `/srv/data/homepage/config/`. Это нарушает принцип "everything as code" и不方便 для управления. Нужно сделать конфиги частью репозитория с автоматическим применением при деплое.

## Problem Analysis

**Что делаем и зачем:**

Homepage - это главная страница homelab с навигацией по всем сервисам. Сейчас конфиги хранятся на сервере в `/srv/data/homepage/config/`, что означает:
- ❌ Нет git контроля изменений
- ❌ Нужно редактировать на сервере через SSH/nano
- ❌ Сложно бэкапить отдельно от данных
- ❌ Нет version control

**Решение:**

Перенести конфиги в репозиторий в `compose/homepage/config/` и монтировать их оттуда. Это даст:
- ✅ Все конфиги в git
- ✅ Редактирование локально в любимом редакторе
- ✅ Version control и history
- ✅ Легкий rollback
- ✅ Конфиги applying автоматически при деплое

**Текущие сервисы для добавления:**
- Traefik (reverse proxy)
- Homepage (сам dashboard)
- Glances (system monitoring)
- Traefik Avahi Helper (mDNS publisher)

## Questions Resolved
- Q: Нужна ли возможность редактирования через веб-интерфейс?
  A: Нет, редактирование будет через YAML файлы в репозитории (предпочтительный вариант для "infrastructure as code")

- Q: Что делать с чувствительными данными?
  A: Вынести в `.env` или использовать переменные окружения. Для текущих сервисов чувствительных данных нет

- Q: Что с существующими конфигами на сервере?
  A: Они будут заменены при деплое. Пользователь должен сохранить нужное содержимое перед деплоем

## Edge Cases & Considerations
- [ ] **Существующие конфиги на сервере** → Пользователь должен сохранить текущие конфиги перед деплоем (если там что-то важное)
- [ ] **Docker socket доступ** → Homepage уже имеет доступ к docker.sock для виджетов ресурсов
- [ ] **Path mismatch** → Изменится путь монтирования с `/srv/data/homepage/config` на `./homepage/config`
- [ ] **Бэкапы** → Старые конфиги в `/srv/data/` больше не нужны (будут в репозитории)
- [ ] **Будущие сервисы** → При добавлении новых сервисов нужно добавлять их в конфиги Homepage

## Relevant Context
- `compose/compose.yml:106-139` - Текущая конфигурация Homepage с volume на `/srv/data`
- `infra/homepage/config-examples/` - Примеры конфигов (будут заменены на полноценные)
- `docs/03_deploy.md` - Процесс деплоя
- `docs/04_backup_restore.md` - Система бэкапов

## Feature Steps

- [x] **Создана директория для конфигов Homepage в репозитории**
  - **Business Value**: Централизованное хранение всех конфигов в одном месте
  - **Depends on**: none
  - **Definition of Done**:
    - [x] Создана директория `compose/homepage/config/`
    - [x] Структура соответствует требованиям Homepage
  - **Touches**: `compose/homepage/config/` (новая директория)

- [x] **Создан полноценный settings.yaml**
  - **Business Value**: Базовая настройка внешнего вида Homepage с логотипом, цветовой схемой и layout
  - **Depends on**: "Создана директория для конфигов Homepage в репозитории"
  - **Definition of Done**:
    - [x] Создан `compose/homepage/config/settings.yaml`
    - [x] Настроены title, subtitle, logo
    - [x] Настроена цветовая схема (dark theme)
    - [x] Настроен background (изображение космоса)
    - [x] Настроен layout (Infrastructure секция)
  - **Touches**: `compose/homepage/config/settings.yaml`

- [x] **Создан services.yaml с текущими сервисами**
  - **Business Value**: Отображение всех текущих сервисов с их статусами (online/offline) и описанием
  - **Depends on**: "Создана директория для конфигов Homepage в репозитории"
  - **Definition of Done**:
    - [x] Создан `compose/homepage/config/services.yaml`
    - [x] Добавлена группа "Infrastructure"
    - [x] Добавлен сервис Traefik с widget (тип traefik)
    - [x] Добавлен сервис Glances с widget (тип glances)
    - [x] Все сервисы используют `.home.local` домены
  - **Touches**: `compose/homepage/config/services.yaml`

- [x] **Создан bookmarks.yaml с быстрыми ссылками**
  - **Business Value**: Быстрый доступ к основным сервисам и полезным ссылкам
  - **Depends on**: "Создана директория для конфигов Homepage в репозитории"
  - **Definition of Done**:
    - [x] Создан `compose/homepage/config/bookmarks.yaml`
    - [x] Добавлена группа "Infrastructure" с ссылками на Traefik, Glances
    - [x] Добавлены описания для каждой ссылки
    - [x] Используются аббревиатуры (TF, GL)
  - **Touches**: `compose/homepage/config/bookmarks.yaml`

- [x] **Создан widgets.yaml с информационными виджетами**
  - **Business Value**: Отображение полезной информации на дашборде (ресурсы системы, дата/время, погода)
  - **Depends on**: "Создана директория для конфигов Homepage в репозитории"
  - **Definition of Done**:
    - [x] Создан `compose/homepage/config/widgets.yaml`
    - [x] Добавлен виджет ресурсов (CPU, RAM, disk)
    - [x] Добавлен виджет погоды (Kaliningrad)
    - [x] Добавлен виджет логотипа
    - [x] Виджет даты/времени не добавлен (по просьбе пользователя)
  - **Touches**: `compose/homepage/config/widgets.yaml`

- [x] **Создан docker.yaml для мониторинга контейнеров**
  - **Business Value**: Отображение статуса всех Docker контейнеров на дашборде
  - **Depends on**: "Создана директория для конфигов Homepage в репозитории"
  - **Definition of Done**:
    - [x] Docker виджет не создан (по просьбе пользователя - не нужен)
  - **Touches**: `compose/homepage/config/docker.yaml`

- [x] **Изменён volume в compose.yml для Homepage**
  - **Business Value**: Homepage использует конфиги из репозитория вместо `/srv/data`
  - **Depends on**: Все предыдущие шаги
  - **Definition of Done**:
    - [x] Изменён volume в `compose/compose.yml` для сервиса homepage
    - [x] Старый volume: `/srv/data/homepage/config:/app/config`
    - [x] Новый volume: `./homepage/config:/app/config:ro` (read-only)
    - [x] Добавлен комментарий о новом расположении конфигов
  - **Touches**: `compose/compose.yml`

- [x] **Обновлена документация**
  - **Business Value**: Пользователь знает, как редактировать конфиги и где они находятся
  - **Depends on**: "Изменён volume в compose.yml для Homepage"
  - **Definition of Done**:
    - [x] Полностью переписан `infra/homepage/README.md` с новой информацией
    - [x] Добавлена инструкция по редактированию конфигов (локально и на сервере)
    - [x] Добавлена инструкция по добавлению новых сервисов
    - [x] Добавлен раздел troubleshooting
  - **Touches**: `infra/homepage/README.md`, `docs/03_deploy.md`

- [ ] **Добавлен .gitignore для чувствительных данных**
  - **Business Value**: Защита от случайного коммита чувствительных данных (API ключи, пароли)
  - **Depends on**: none
  - **Definition of Done**:
    - [ ] Добавлен `compose/homepage/config/.gitignore` для будущих чувствительных файлов
    - [ ] Или добавлены глобальные правила в основной `.gitignore`
  - **Touches**: `compose/homepage/config/.gitignore` (новый файл) или корневой `.gitignore`

## Testing Strategy

⚠️ **Примечание**: Основное тестирование будет выполняться пользователем на сервере.

**Мануальное тестирование (пользователем):**
1. Сохранить текущие конфиги с сервера (если нужно):
   ```bash
   cp -r /srv/data/homepage/config ~/homepage-config-backup
   ```
2. Применить изменения: `./scripts/deploy.sh`
3. Проверить, что Homepage запустился: `docker ps | grep homepage`
4. Проверить логи: `docker logs homelab-homepage`
5. Открыть `http://home.local` в браузере
6. Проверить, что:
   - Отображаются все сервисы (Traefik, Glances, Homepage)
   - Работают виджеты (ресурсы, дата/время)
   - Работают bookmarks
   - Правильный внешний вид (логотип, цвета, background)
7. Проверить, что Docker контейнеры отображаются в виджете
8. Редактирование конфигов в репозитории применяется при `./scripts/deploy.sh`

**Проверка локально (до деплоя):**
- Валидация YAML синтаксиса
- Проверка структуры файлов
- Проверка соответствия документации Homepage

## Notes

- **Важно**: Конфиги больше НЕ будут редактироваться через веб-интерфейс Homepage. Все изменения - через YAML файлы в репозитории.
- **Совет**: После деплоя можно удалить `/srv/data/homepage/` (если там больше ничего нет)
- **Future**: При добавлении новых сервисов нужно добавлять их в `services.yaml`, `bookmarks.yaml`, и опционально в `docker.yaml`
- **Backup**: Старые конфиги в `/srv/data/homepage/config/` больше не бэкапятся (теперь они в репозитории, который бэкапится через `BACKUP_TARGETS`)
