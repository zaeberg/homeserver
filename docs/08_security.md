# Security Guidelines

Этот документ описывает best practices по безопасности homeserver'а, управлению секретами, настройке firewall и защите сервисов.

## Управление секретами

### Хранение секретов

**Правило**: Никогда не коммитить секреты в git!

Где хранить секреты:
- `compose/.env` — **не коммитится** (в `.gitignore`)
- Docker secrets (для Swarm)
- Password manager (Bitwarden, 1Password, KeePass)

### Шаблон .env.example

```bash
# compose/.env.example — безопасный шаблон (можно коммитить)
# Содержит только ключи без значений или с placeholder'ами

BASE_URL=http://home.local
RESTIC_PASSWORD=CHANGE_THIS_TO_SECURE_PASSWORD
```

### Создание .env на сервере

```bash
# 1. Скопировать шаблон
cp compose/.env.example compose/.env

# 2. Установить безопасные права (только для владельца)
chmod 600 compose/.env

# 3. Отредактировать и заполнить секреты
nano compose/.env
```

### Password Manager

**Рекомендация**: Хранить все секреты в password manager

**Что хранить**:
- `.env` файл (как secure note)
- RESTIC_PASSWORD — ключ для восстановления бэкапов
- Basic Auth credentials (если используется)
- Let's Encrypt account key (когда будет настроен)
- API keys (если сервисы требуют)

### Ротация секретов

**RESTIC_PASSWORD** (критично!):
- Ротация требует создания нового репозитория
- Запланируйте заранее: добавьте новый backup job до удаления старого

**Basic Auth**:
```bash
# Сгенерировать новый хеш
echo $(htpasswd -nb admin newpassword) | sed -e s/\\$/\\$\\$/g

# Обновить compose/traefik/dynamic.yml
# Перезапустить Traefik
docker compose -f compose/compose.yml restart traefik
```

## Firewall (UFW)

### Базовая настройка

```bash
# 1. Установить UFW
sudo apt install ufw

# 2. Настроить default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. Разрешить SSH (ПЕРЕД включением firewall!)
sudo ufw allow 22/tcp comment 'SSH'

# 4. Разрешить HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP (Traefik)'
sudo ufw allow 443/tcp comment 'HTTPS (Traefik)'

# 5. (Опционально) Ограничить Traefik Dashboard локальной сетью
sudo ufw allow from 192.168.1.0/24 to any port 8080 comment 'Traefik Dashboard - LAN only'

# 6. Включить firewall
sudo ufw enable

# 7. Проверить статус
sudo ufw status verbose
```

### Правила для локальной сети

```bash
# Разрешить весь трафик из локальной сети (доверенная)
sudo ufw allow from 192.168.1.0/24

# Или разрешить specific порты:
sudo ufw allow from 192.168.1.0/24 to any port 8080 comment 'Traefik Dashboard'
sudo ufw allow from 192.168.1.0/24 to any port 9090 comment 'Portainer'
```

### Блокировка brute-force

```bash
# Ограничить количество попыток SSH
sudo ufw limit 22/tcp

# После 6 попыток за 30 секунд — ban на 30 секунд
```

## Traefik Dashboard Security

### Вариант 1: Basic Auth (Рекомендуется)

**Шаг 1**: Сгенерировать хеш пароля

```bash
# Установить htpasswd (если нет)
sudo apt install apache2-utils

# Сгенерировать хеш
echo $(htpasswd -nb admin mysecurepassword) | sed -e s/\\$/\\$\\$/g
# Результат: admin:$apr1$hash...
```

**Шаг 2**: Добавить middleware в `compose/traefik/dynamic.yml`

```yaml
http:
  middlewares:
    traefik-auth:
      basicAuth:
        users:
          - "admin:$apr1$hash..."  # Замените на ваш хеш

    # ... существующие middlewares ...

  routers:
    dashboard:
      rule: "Host(`traefik.home.local`)"
      service: "api@internal"
      entryPoints:
        - "web"
      middlewares:
        - "dashboard-to-root"
        - "traefik-auth"  # Добавить Basic Auth
```

**Шаг 3**: Перезапустить Traefik

```bash
docker compose -f compose/compose.yml restart traefik
```

**Шаг 4**: Проверить

```bash
curl -I http://traefik.home.local/dashboard/
# Должно вернуть: 401 Unauthorized
```

### Вариант 2: Ограничение по IP (Доверенная LAN)

Добавить middleware в `compose/traefik/dynamic.yml`:

```yaml
http:
  middlewares:
    ip-whitelist:
      ipWhiteList:
        sourceRange:
          - "192.168.1.0/24"  # Ваша локальная сеть
          - "127.0.0.1/32"    # Localhost

  routers:
    dashboard:
      rule: "Host(`traefik.home.local`)"
      service: "api@internal"
      entryPoints:
        - "web"
      middlewares:
        - "dashboard-to-root"
        - "ip-whitelist"  # Только из LAN
```

### Вариант 3: Отключение insecure API

**Важно**: Убрать `insecure: true` из `compose/traefik/traefik.yml`

```yaml
# ❌ Плохо (Dashboard доступен без auth)
api:
  dashboard: true
  insecure: true  # УБРАТЬ!

# ✅ Хорошо (Dashboard только через middleware)
api:
  dashboard: true
```

**После этого**:
1. Dashboard недоступен напрямую на `http://server:8080/dashboard/`
2. Доступен только через Traefik routing с middleware

## HTTPS с Let's Encrypt

### Подготовка

**Требования**:
- Доменное имя (не `.home.local`!)
- DNS A record指向 ваш IP (например, `homeserver.example.com → 1.2.3.4`)
- Открытый порт 443 (firewall)

### Настройка Traefik

**Шаг 1**: Раскомментировать в `compose/traefik/traefik.yml`:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com  # Ваш email
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

**Шаг 2**: Создать volume для сертификатов

```yaml
# В compose/compose.yml
services:
  traefik:
    volumes:
      # ... существующие volumes ...
      - /srv/data/traefik/letsencrypt:/letsencrypt
```

**Шаг 3**: Настроить router с TLS

```yaml
# В compose/compose.yml или labels сервиса
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.myservice.rule=Host(`myservice.example.com`)"
  - "traefik.http.routers.myservice.entrypoints=websecure"
  - "traefik.http.routers.myservice.tls=true"
  - "traefik.http.routers.myservice.tls.certresolver=letsencrypt"
  - "traefik.http.services.myservice.loadbalancer.server.port=8080"
```

**Шаг 4**: Перезапустить Traefik

```bash
docker compose -f compose/compose.yml restart traefik
```

### Перенаправление HTTP → HTTPS

Добавить middleware в `compose/traefik/dynamic.yml`:

```yaml
http:
  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true

  routers:
    # Для всех сервисов
    myservice-http:
      rule: "Host(`myservice.example.com`)"
      entryPoints:
        - "web"
      middlewares:
        - "redirect-to-https"
      service: myservice

    myservice-https:
      rule: "Host(`myservice.example.com`)"
      entryPoints:
        - "websecure"
      tls:
        certResolver: letsencrypt
      service: myservice
```

## Docker Security

### 1. Не запускать от root

```yaml
# ❌ Плохо
services:
  myservice:
    user: "root"

# ✅ Хорошо
services:
  myservice:
    user: "1000:1000"  # UID:GID
```

### 2. Readonly filesystem (где возможно)

```yaml
services:
  nginx:
    image: nginx:latest
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /tmp
```

### 3. Resource limits

```yaml
services:
  myservice:
    image: myservice:latest
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

### 4. Capabilities drop

```yaml
services:
  myservice:
    image: myservice:latest
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Только если нужно слушать порт
```

### 5. Security options

```yaml
services:
  myservice:
    image: myservice:latest
    security_opt:
      - no-new-privileges:true
```

## Network Security

### 1. Разделение сетей

```yaml
# ✅ Хорошо: базы данных в isolated сети
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # Без выхода в интернет

services:
  webapp:
    networks:
      - frontend
      - backend

  database:
    networks:
      - backend  # Только backend, не frontend
```

### 2. Не expose порты

```yaml
# ❌ Плохо: порт доступен напрямую
services:
  myservice:
    ports:
      - "8080:8080"

# ✅ Хорошо: только через Traefik
services:
  myservice:
    networks:
      - internal  # Нет прямого доступа
```

## SSH Security

### 1. Disable root login

```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no  # Только keys
```

### 2. Использовать SSH keys

```bash
# На клиенте: сгенерировать ключ
ssh-keygen -t ed25519 -C "your-email@example.com"

# Скопировать на сервер
ssh-copy-id user@homeserver.local

# Отключить password auth после проверки key auth
```

### 3. Fail2ban (защита от brute-force)

```bash
# Установить
sudo apt install fail2ban

# Настроить /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
```

## Monitoring безопасности

### 1. Логи Traefik

```bash
# Смотреть логи в real-time
docker logs -f homelab-traefik

# Искать подозрительную активность
docker logs homelab-traefik | grep -i "error\|warning"
```

### 2. Аудит Docker

```bash
# Проверить запущенные контейнеры
docker ps

# Проверить изменения в образах
docker diff homelab-traefik

# Проверить security scan
docker scout cves traefik:v3.6.7
```

### 3. Log rotation

```bash
# Настроить logrotate для Docker containers
# /etc/logrotate.d/docker-containers

/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    missingok
    delaycompress
    copytruncate
}
```

## Backup секретов

**Критично**: Резервировать `.env` файл!

```bash
# Сохранить в password manager
cat compose/.env | pbcopy  # macOS
cat compose/.env | xclip   # Linux

# Или зашифрованный backup
gpg --symmetric --cipher-algo AES256 compose/.env
# Результат: compose/.env.gpg
```

## Checklist безопасности

Перед productive use:

- [ ] Firewall (UFW) включён и настроен
- [ ] Traefik Dashboard защищён Basic Auth или IP whitelist
- [ ] `insecure: true` убран из `traefik.yml`
- [ ] `.env` файл имеет права `600`
- [ ] SSH password authentication отключён
- [ ] Root login по SSH отключён
- [ ] Все секреты сохранены в password manager
- [ ] `.env` добавлен в backup (отдельно от кода)
- [ ] Docker контейнеры не запускаются от root (где возможно)
- [ ] Логи ротируются
- [ ] Fail2ban установлен и настроен
- [ ] Restic backup протестирован (restore test)

## Дальнейшее чтение

- `docs/00_architecture.md` — архитектура сетей
- `docs/07_adding_services.md` — добавление сервисов с security
- `docs/05_operations.md` — логирование и мониторинг
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Traefik Security Documentation](https://doc.traefik.io/traefik/security/)
