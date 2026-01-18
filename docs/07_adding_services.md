# Добавление новых сервисов

Этот guide объясняет, как добавлять новые сервисы в homeserver с автоматической маршрутизацией через Traefik.

## Требования к сервису

Перед добавлением сервиса убедитесь, что он соответствует следующим требованиям:

1. **Docker-образ** — сервис должен быть доступен как Docker image
2. **HTTP/HTTPS порт** — сервис должен слушать HTTP порт (обычно 80, 8080, 3000, etc.)
3. **Stateless или volumes** — если сервис хранит данные, нужно определить volumes
4. **Нет конфликтов портов** — порт не должен конфликтовать с существующими сервисами

## Минимальная конфигурация сервиса

### Пример: Whoami (тестовый сервис)

```yaml
# В compose/compose.yml

services:
  whoami:
    image: traefik/whoami:latest
    container_name: homelab-whoami
    restart: unless-stopped
    networks:
      - internal
    labels:
      # Включить Traefik для этого контейнера
      - "traefik.enable=true"

      # Router: правило маршрутизации по hostname
      - "traefik.http.routers.whoami.rule=Host(`whoami.home.local`)"

      # Service: какой порт контейнера использовать
      - "traefik.http.services.whoami.loadbalancer.server.port=80"

      # EntryPoint: какой порт Traefik слушать (web = 80, websecure = 443)
      - "traefik.http.routers.whoami.entrypoints=web"

      # mDNS: публикация в локальной сети
      - "avahi.homeserver.service=Whoami Test Service"
      - "avahi.homeserver.protocol=http"
```

### Разбор labels

| Label | Назначение | Обязательный? |
|-------|-----------|---------------|
| `traefik.enable=true` | Включает Traefik для контейнера | ✅ Да |
| `traefik.http.routers.<name>.rule` | Правило маршрутизации (hostname) | ✅ Да |
| `traefik.http.services.<name>.loadbalancer.server.port` | Порт контейнера | ✅ Да |
| `traefik.http.routers.<name>.entrypoints` | EntryPoint (web/websecure) | ✅ Да |
| `avahi.homeserver.service` | Название сервиса в mDNS | ⚠️ Рекомендуется |
| `avahi.homeserver.protocol` | Протокол (http/https) | ⚠️ Рекомендуется |

### Полный пример с volumes и environment

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: homelab-nginx
    restart: unless-stopped
    volumes:
      - /srv/data/nginx/html:/usr/share/nginx/html:ro
      - /srv/data/nginx/conf:/etc/nginx/conf.d:ro
    networks:
      - internal
    environment:
      - TZ=Europe/Moscow
    labels:
      # Traefik labels
      - "traefik.enable=true"
      - "traefik.http.routers.nginx.rule=Host(`nginx.home.local`)"
      - "traefik.http.services.nginx.loadbalancer.server.port=80"
      - "traefik.http.routers.nginx.entrypoints=web"

      # mDNS labels
      - "avahi.homeserver.service=Nginx Web Server"
      - "avahi.homeserver.protocol=http"
```

## Расширенные примеры

### 1. С HTTPS (с использованием Let's Encrypt)

**Важно**: Let's Encrypt ещё не настроен в этом проекте. Это пример для будущего использования.

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.example.com`)"
  - "traefik.http.routers.myservice.entrypoints=websecure"
  - "traefik.http.routers.myservice.tls=true"
  - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### 2. С Basic Auth

**Шаг 1**: Сгенерируйте хеш пароля

```bash
echo $(htpasswd -nb admin mysecurepassword) | sed -e s/\\$/\\$\\$/g
# Результат: admin:$apr1$hash...
```

**Шаг 2**: Добавьте middleware в `compose/traefik/dynamic.yml`

```yaml
http:
  middlewares:
    myservice-auth:
      basicAuth:
        users:
          - "admin:$apr1$hash..."
```

**Шаг 3**: Примените middleware к сервису

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.home.local`)"
  - "traefik.http.routers.myservice.entrypoints=web"
  - "traefik.http.routers.myservice.middlewares=myservice-auth@file"  # @file значит берётся из dynamic.yml
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### 3. С security headers

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.home.local`)"
  - "traefik.http.routers.myservice.entrypoints=web"
  - "traefik.http.routers.myservice.middlewares=security-headers@file"  # уже определён в dynamic.yml
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### 4. С rate limiting (защита от DDoS)

**Шаг 1**: Добавьте middleware в `compose/traefik/dynamic.yml`

```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100  # среднее количество запросов
        period: 1m    # за 1 минуту
        burst: 50     # пиковое количество запросов
```

**Шаг 2**: Примените middleware

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.home.local`)"
  - "traefik.http.routers.myservice.entrypoints=web"
  - "traefik.http.routers.myservice.middlewares=rate-limit@file,security-headers@file"
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

### 5. С несколькими middlewares

Middlewares применяются в порядке указания (слева направо):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.home.local`)"
  - "traefik.http.routers.myservice.entrypoints=web"
  # Порядок: сначала rate-limit, потом basicAuth, потом security-headers
  - "traefik.http.routers.myservice.middlewares=rate-limit@file,myservice-auth@file,security-headers@file"
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

## Пошаговое добавление сервиса

### 1. Подготовка

```bash
# Перейдите в директорию проекта
cd /srv/homelab/homelab-server

# Создайте директории для данных (если нужно)
sudo mkdir -p /srv/data/myservice
```

### 2. Редактирование compose.yml

```bash
# Откройте compose/compose.yml
nano compose/compose.yml

# Добавьте сервис в секцию services:
```

```yaml
services:
  # ... существующие сервисы ...

  myservice:
    image: myservice:latest
    container_name: homelab-myservice
    restart: unless-stopped
    volumes:
      - /srv/data/myservice:/data
    networks:
      - internal
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.home.local`)"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"
      - "traefik.http.routers.myservice.entrypoints=web"
      - "avahi.homeserver.service=My Service"
      - "avahi.homeserver.protocol=http"
```

### 3. Валидация конфигурации

```bash
# Проверьте конфигурацию без запуска
./scripts/validate.sh

# Или вручную:
docker compose -f compose/compose.yml config
```

### 4. Деплой

```bash
# Запустите деплой (перезапустит все сервисы)
./scripts/deploy.sh

# Или запустите только новый сервис:
docker compose -f compose/compose.yml up -d myservice
```

### 5. Проверка

```bash
# Проверьте, что контейнер запущен
docker ps | grep myservice

# Проверьте логи
docker logs homelab-myservice

# Проверьте доступность (с сервера)
curl -I http://myservice.home.local

# Проверьте в Traefik Dashboard
open http://traefik.home.local/dashboard/
# http://traefik.home.local/dashboard/#/http/routers
```

## Troubleshooting

### Сервис недоступен по hostname

**Проблема**: `curl: (6) Could not resolve host: myservice.home.local`

**Решение**:
1. Проверьте, что `avahi.homeserver.service` label добавлен
2. Проверьте, что `traefik-avahi` контейнер запущен:
   ```bash
   docker ps | grep avahi
   ```
3. Проверьте логи `traefik-avahi`:
   ```bash
   docker logs homelab-traefik-avahi-helper
   ```
4. Установите `avahi-daemon` на хост-системе (если не установлен):
   ```bash
   sudo apt install avahi-daemon
   ```

### Traefik не видит сервис

**Проблема**: Сервис не появляется в Traefik Dashboard

**Решение**:
1. Проверьте, что `traefik.enable=true` label добавлен
2. Проверьте, что контейнер в сети `internal`:
   ```bash
   docker inspect homelab-myservice | grep -A 10 Networks
   ```
3. Проверьте логи Traefik:
   ```bash
   docker logs homelab-traefik | grep myservice
   ```
4. Проверьте, что `exposedByDefault: false` в `traefik.yml` (это корректно, нужны explicit labels)

### 502 Bad Gateway от Traefik

**Проблема**: Traefik показывает ошибку 502

**Решение**:
1. Проверьте, что порт в `loadbalancer.server.port` совпадает с портом контейнера
2. Проверьте, что сервис действительно слушает этот порт:
   ```bash
   docker exec homelab-myservice netstat -tlnp
   ```
3. Проверьте healthcheck контейнера:
   ```bash
   docker inspect homelab-myservice | grep -A 10 Health
   ```

### Порт уже занят

**Проблема**: `port is already allocated`

**Решение**:
1. Не публикуйте порты (`ports:`), если не нужно
2. Используйте только внутренние порты (контейнер → контейнер через Traefik)
3. Если нужен внешний доступ, используйте Traefik routing вместо `ports:`

## Best Practices

### 1. Именование

- **Container name**: `homelab-<servicename>` (например, `homelab-nginx`)
- **Router name**: `<servicename>` (например, `nginx`)
- **Service name**: `<servicename>` (например, `nginx`)

### 2. Сети

- Все сервисы должны быть в сети `internal`
- Используйте `public` сеть только для сервисов, которые должны быть доступны из интернета

### 3. Версионирование образов

```yaml
# ❌ Плохо (может обновиться до breaking changes)
image: nginx:latest

# ✅ Хорошо (фиксированная версия)
image: nginx:1.25

# ✅ Ещё лучше (фиксированный digest)
image: nginx:1.25@sha256:abc123...
```

### 4. Resource limits

```yaml
services:
  myservice:
    image: myservice:latest
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 5. Healthchecks

```yaml
services:
  myservice:
    image: myservice:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 6. Volumes

```yaml
# Используйте named volumes или bind mounts явно
volumes:
  - /srv/data/myservice:/data  # bind mount
  - myservice-config:/etc/myservice  # named volume

# Readonly где возможно
volumes:
  - /srv/data/myservice/config:/etc/myservice:ro
```

## Примеры реальных сервисов

### Portainer (Docker UI)

```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: homelab-portainer
    restart: unless-stopped
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /srv/data/portainer:/data
    networks:
      - internal
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(`portainer.home.local`)"
      - "traefik.http.services.portainer.loadbalancer.server.port=9443"
      - "traefik.http.routers.portainer.entrypoints=web"
      - "traefik.http.routers.portainer.service=portainer"
      - "traefik.http.services.portainer.loadbalancer.server.scheme=http"
      - "avahi.homeserver.service=Portainer"
      - "avahi.homeserver.protocol=http"
```

### Nginx Proxy Manager (альтернатива Traefik)

```yaml
services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: homelab-npm
    restart: unless-stopped
    ports:
      - '8080:80'   # Public HTTP
      - '8081:81'   # Management interface
      - '8082:443'  # Public HTTPS
    volumes:
      - /srv/data/npm/data:/data
      - /srv/data/npm/letsencrypt:/etc/letsencrypt
    networks:
      - internal
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.npm.rule=Host(`npm.home.local`)"
      - "traefik.http.services.npm.loadbalancer.server.port=81"
      - "traefik.http.routers.npm.entrypoints=web"
      - "avahi.homeserver.service=Nginx Proxy Manager"
      - "avahi.homeserver.protocol=http"
```

## Дальнейшее чтение

- `docs/00_architecture.md` — архитектура системы
- `docs/08_security.md` — security guidelines
- `docs/05_operations.md` — операции обслуживания
- [Traefik Documentation](https://doc.traefik.io/traefik/)
