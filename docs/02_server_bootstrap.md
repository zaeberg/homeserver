# Server Bootstrap

Этот документ описывает начальную установку и настройку ОС на miniPC перед развёртыванием homelab сервера.

**ВАЖНО**: Это выполняется один раз при первоначальной установке сервера.

## Требования к оборудованию

- **Минимум**: 2GB RAM, 20GB диска, 1 CPU core
- **Рекомендуется**: 4GB+ RAM, 50GB+ SSD, 2+ CPU cores
- **Сеть**: Ethernet connection с доступом в локальную сеть

---

## Step S1: Установка Ubuntu Server 24.04 LTS

### 1.1 Скачать Ubuntu Server

```bash
# На локальной машине
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
```

### 1.2 Создать загрузочный USB

```bash
# На Linux
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress sync

# На macOS
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/rdiskN bs=4m
```

### 1.3 Установить ОС

1. Загрузитесь с USB на miniPC
2. Выберите "Install Ubuntu Server"
3. Следуйте инструкциям:
   - **Language**: English (или ваш язык)
   - **Keyboard layout**: выберите вашу раскладку
   - **Network**: используйте Ethernet (wired)
   - **Proxy**: оставьте пустым (если нет)
   - **Mirror**: выберите ближайший
   - **Storage**: используйте весь диск (LVM recommended)
   - **User profile**:
     - Имя пользователя: `admin` (или другое)
     - Пароль: **Надёжный пароль!**
4. Дождитесь окончания установки
5. Перезагрузитесь и выньте USB

### 1.4 Обновить систему

```bash
# После первого входа в систему
sudo apt update && sudo apt upgrade -y
```

---

## Step S2: Firewall и директории

### 2.1 Настроить UFW (Firewall)

```bash
# Разрешить SSH
sudo ufw allow 22/tcp

# Разрешить HTTP (для Caddy)
sudo ufw allow 80/tcp

# Включить firewall
sudo ufw enable

# Проверить статус
sudo ufw status verbose
```

Ожидаемый вывод:
```
Status: active
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
```

### 2.2 Создать директории

```bash
# Создать структуру директорий
sudo mkdir -p /srv/homelab
sudo mkdir -p /srv/data

# Проверить права
ls -la /srv/
```

---

## Step S3: Установка Docker

### 3.1 Установить Docker Engine

Следуйте официальной инструкции: https://docs.docker.com/engine/install/ubuntu/

Краткая версия:

```bash
# Удалить старые версии (если есть)
sudo apt remove docker docker-engine docker.io containerd runc

# Установить зависимости
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Добавить Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавить Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установить Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Проверить установку
docker --version
docker compose version
```

### 3.2 Добавить пользователя в группу docker

```bash
# Добавить текущего пользователя в группу docker
sudo usermod -aG docker $USER

# Применить изменения (выйти и зайти снова, или)
newgrp docker

# Проверить, что docker работает без sudo
docker ps
```

Если команда `docker ps` работает без `sudo` — всё настроено верно.

### 3.3 Настроить Docker daemon

```bash
# Скопировать конфигурацию из репозитория
# (после копирования repo на сервер, см. Step S4)

# Или создать вручную
sudo mkdir -p /etc/docker
sudo nano /etc/docker/daemon.json
```

Содержимое `daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

### 3.4 Перезапустить Docker

```bash
# Перезапустить Docker с новой конфигурацией
sudo systemctl restart docker

# Включить автозапуск Docker
sudo systemctl enable docker

# Проверить статус
sudo systemctl status docker
```

---

## Step S4: Размещение репозитория

### 4.1 Скопировать репозиторий на сервер

**Вариант A: Через SCP (с локальной машины)**

```bash
# На локальной машине
scp -r /path/to/homeserver admin@<SERVER_IP>:/tmp/
```

**Вариант B: Через Git (если репозиторий в git)**

```bash
# На сервере
sudo apt install git
cd /srv/homelab
git clone <repo-url> homelab-server
```

**Вариант C: Через USB**

```bash
# Скопировать файлы с USB на сервер
sudo cp -r /media/usb/homeserver /srv/homelab/homelab-server
```

### 4.2 Настроить права доступа

```bash
# Переместить репозиторий в нужное место
sudo mv /tmp/homeserver /srv/homelab/homelab-server

# Сменить владельца на текущего пользователя
sudo chown -R $USER:$USER /srv/homelab/homelab-server

# Проверить структуру
ls -la /srv/homelab/homelab-server/
```

### 4.3 Создать .env файл

```bash
cd /srv/homelab/homelab-server

# Создать .env из шаблона
cp compose/.env.example compose/.env

# Ограничить права доступа (очень важно!)
chmod 600 compose/.env

# Отредактировать .env
nano compose/.env
```

**Минимальная конфигурация `.env`:**
```bash
# Базовый URL (замените IP на реальный)
BASE_URL=http://192.168.1.100

# Vaultwarden — сгенерируйте надёжный токен
VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -base64 48)
VAULTWARDEN_SIGNUPS_ALLOWED=false

# Filebrowser
FILEBROWSER_USERNAME=admin
FILEBROWSER_PASSWORD=your_secure_password_here

# Restic (будет настроен в Step S5)
RESTIC_REPO=/mnt/backup/restic
RESTIC_PASSWORD=your_restic_password_here
```

### 4.4 Создать директории для данных

```bash
# Создать все необходимые директории
sudo mkdir -p /srv/data/{vaultwarden,syncthing,filebrowser,uptime-kuma,caddy,backup}

# Назначить права доступа
sudo chown -R $USER:$USER /srv/data
chmod -R 755 /srv/data

# Проверить
ls -la /srv/data/
```

---

## Step S5: Backup Storage

Выберите один из трёх вариантов бэкапа:

1. **Только внешний диск** — быстро, надёжно
2. **Только Яндекс Диск** — защита от потери сервера
3. **Гибридный** — внешний диск + Яндекс Диск одновременно

---

### Вариант 1: Внешний диск

Подключите внешний диск к серверу.

```bash
# Найти диск
sudo lsblk

# Создать файловую систему (замените /dev/sdb на ваш диск)
sudo mkfs.ext4 /dev/sdb1

# Создать точку монтирования
sudo mkdir -p /mnt/backup

# Смонтировать
sudo mount /dev/sdb1 /mnt/backup

# Добавить в fstab для автозагрузки
UUID=$(sudo blkid -s UUID -o value /dev/sdb1)
echo "UUID=$UUID /mnt/backup ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

Установить Restic и инициализировать репозиторий:

```bash
sudo apt install restic

cd /srv/homelab/homelab-server

# Настроить .env
nano compose/.env
```

Добавьте в `compose/.env`:
```bash
RESTIC_REPO_LOCAL=/mnt/backup/restic
RESTIC_REPO_CLOUD=
RESTIC_PASSWORD=ваш_пароль
```

Инициализировать репозиторий:
```bash
source compose/.env

# Создать и инициализировать репозиторий (ВАЖНО: делается один раз!)
sudo mkdir -p $RESTIC_REPO_LOCAL
sudo chown $USER:$USER $RESTIC_REPO_LOCAL
export RESTIC_REPO=$RESTIC_REPO_LOCAL
restic -r /mnt/backup/restic init

# Проверить бэкап
./scripts/backup.sh local
```

**Важно**: Команду `restic init` нужно выполнить **один раз** перед первым бэкапом.

---

### Вариант 2: Яндекс Диск (через rclone)

```bash
# Установить rclone и restic
sudo apt install rclone restic

# Настроить rclone с Yandex Disk
rclone config
```

Интерактивная настройка rclone:
```
No remotes found - make a new one
n) New remote
s) Set configuration password
n/s> n

name> yandex

Type of storage to configure.
Choose a number from below, or type in your own value
XX / Yandex Disk
   \ "yandex"
Storage> yandex

Yandex Client Id - leave blank normally.
client_id> [нажмите Enter]

Yandex Client Secret - leave blank normally.
client_secret> [нажмите Enter]

Use web browser to automatically authenticate rclone with remote?
y) Yes
n) No
y/n> y

[Откроется браузер для авторизации в Яндексе]

Configuration successful.
Keep this "yandex" remote?
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y

q) Quit config
e/n/d/r> q
```

**Проверить подключение:**
```bash
# Посмотреть корневую директорию
rclone lsd yandex:

# Создать директорию для бэкапов
rclone mkdir yandex:homelab-backups

# Проверить квоту
rclone about yandex:
```

Настроить `compose/.env`:
```bash
nano compose/.env
```

Добавьте:
```bash
RESTIC_REPO_LOCAL=
RESTIC_REPO_CLOUD=rclone:yandex:homelab-backups
RESTIC_PASSWORD=ваш_пароль
```

Инициализировать репозиторий:
```bash
source compose/.env

# Инициализировать restic репозиторий (ВАЖНО: делается один раз!)
export RESTIC_REPO=$RESTIC_REPO_CLOUD
restic -r rclone:yandex:homelab-backups init

# Проверить бэкап
./scripts/backup.sh cloud
```

**Важно**:
- Команду `restic init` нужно выполнить **один раз** перед первым бэкапом
- При первом запуске restic может запросить подтверждение запуска rclone — ответьте `y`
- После инициализации бэкапы будут выполняться автоматически через systemd timer

---

### Вариант 3: Гибридный (диск + Яндекс Диск)

Сначала выполните Вариант 1 и Вариант 2. Затем настройте `compose/.env`:

```bash
nano compose/.env
```

Добавьте оба пути:
```bash
RESTIC_REPO_LOCAL=/mnt/backup/restic
RESTIC_REPO_CLOUD=rclone:yandex:homelab-backups
RESTIC_PASSWORD=ваш_пароль
```

Проверить оба бэкапа:
```bash
# Инициализировать ОБА репозитория (один раз!)
export RESTIC_REPO=/mnt/backup/restic
restic -r /mnt/backup/restic init

export RESTIC_REPO=rclone:yandex:homelab-backups
restic -r rclone:yandex:homelab-backups init

# Локальный бэкап
./scripts/backup.sh local

# Облачный бэкап
./scripts/backup.sh cloud

# Проверить снапшоты
restic -r /mnt/backup/restic snapshots --compact

restic -r rclone:yandex:homelab-backups snapshots --compact
```

---

## Step S6: Первый запуск

### 6.1 Запустить деплой

```bash
cd /srv/homelab/homelab-server

# Запустить все сервисы
./scripts/deploy.sh
```

Ожидаемый вывод:
```
=== Homelab Deployment ===

✓ Environment file found
Stopping existing containers (if any)...
Pulling latest images...
Starting services...
Creating network "homelab_internal" ...
Creating network "homelab_public" ...
Creating homelab-caddy ...
Creating homelab-vaultwarden ...
Creating homelab-syncthing ...
Creating homelab-filebrowser ...
Creating homelab-uptime-kuma ...

Container status:
NAME                    STATUS
homelab-caddy           running
homelab-vaultwarden     running
homelab-syncthing       running
homelab-filebrowser     running
homelab-uptime-kuma     running

Running healthcheck...
```

### 6.2 Проверить работоспособность

```bash
# Запустить healthcheck
./scripts/healthcheck.sh
```

Откройте в браузере на **другом устройстве** в локальной сети:
- http://SERVER_IP/ — landing page
- http://SERVER_IP/vault — Vaultwarden
- http://SERVER_IP/sync — Syncthing
- http://SERVER_IP/files — Filebrowser
- http://SERVER_IP/status — Uptime Kuma

### 6.3 Настроить статический IP (опционально)

Рекомендуется настроить статический IP в роутере (DHCP reservation) или на сервере:

```bash
# Найти сетевой интерфейс
ip a

# Отредактировать netplan (Ubuntu 24.04 использует Network Manager)
sudo nano /etc/netplan/00-installer-config.yaml
```

Пример для статического IP:
```yaml
network:
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 192.168.1.1
  version: 2
```

Применить:
```bash
sudo netplan apply
```

---

## Step S7: Автоматизация бэкапов

### Вариант 1: Только внешний диск

```bash
cd /srv/homelab/homelab-server

# Скопировать и включить
sudo cp systemd/homelab-backup-local.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now homelab-backup-local.timer

# Проверить
systemctl list-timers | grep homelab
```

### Вариант 2: Только Яндекс Диск

```bash
cd /srv/homelab/homelab-server

# Скопировать и включить
sudo cp systemd/homelab-backup-cloud.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now homelab-backup-cloud.timer

# Проверить
systemctl list-timers | grep homelab
```

### Вариант 3: Гибридный (диск + Яндекс Диск)

```bash
cd /srv/homelab/homelab-server

# Скопировать все unit файлы
sudo cp systemd/homelab-backup-local.{service,timer} /etc/systemd/system/
sudo cp systemd/homelab-backup-cloud.{service,timer} /etc/systemd/system/
sudo cp systemd/homelab-restore-test.service /etc/systemd/system/

# Перезагрузить и включить оба timer
sudo systemctl daemon-reload
sudo systemctl enable --now homelab-backup-local.timer
sudo systemctl enable --now homelab-backup-cloud.timer

# Проверить расписание
systemctl list-timers | grep homelab
```

Ожидаемый вывод:
```
NEXT                                LEFT          LAST    PASSED    UNIT                        ...
Sun 2025-01-19 03:00:00 MSK  14h left      -      -         homelab-backup-local.timer  ...
Sun 2025-01-19 04:00:00 MSK  15h left      -      -         homelab-backup-cloud.timer  ...
```

---

## Проверка после установки

### Финальный чек-лист

```bash
# 1. Проверить статус контейнеров
docker compose ps

# 2. Проверить логи на ошибки
docker compose logs --tail=50

# 3. Запустить healthcheck
./scripts/healthcheck.sh

# 4. Проверить бэкап
restic snapshots
sudo systemctl status homelab-backup.timer

# 5. Проверить дисковое пространство
df -h

# 6. Проверить RAM
free -h

# 7. Проверить открытые порты
sudo ss -tulpn | grep LISTEN
```

Все проверки должны пройти успешно.

---

## Следующие шаги

После завершения bootstrap:

1. **Настроить приложения**:
   - Создать учётную запись в Vaultwarden
   - Настроить Syncthing устройства
   - Создать мониторы в Uptime Kuma

2. **Настроить внешний доступ** (опционально):
   - Настроить динамический DNS (No-IP, DuckDNS)
   - Настроить проброс портов на роутере (только 80/tcp)
   - Настроить HTTPS в Caddy (если есть домен)

3. **Регулярное обслуживание**:
   - Обновлять контейнеры (см. `05_operations.md`)
   - Проверять бэкапы еженедельно
   - Проверять дисковое пространство

Подробная инструкция в документах `03_deploy.md` и `05_operations.md`.

---

## Troubleshooting

### Проблема: Docker не работает без sudo

**Решение**:
```bash
# Убедитесь, что пользователь в группе docker
groups $USER

# Если нет, добавьте
sudo usermod -aG docker $USER

# Выйдите и войдите снова, или
newgrp docker
```

### Проблема: Диск не монтируется при загрузке

**Решение**:
```bash
# Проверить UUID диска
sudo blkid

# Проверить /etc/fstab
cat /etc/fstab

# Проверить монтирование
sudo mount -a
```

### Проблема: Контейнеры не стартуют

**Решение**:
```bash
# Проверить логи
docker compose logs

# Проверить валидацию
./scripts/validate.sh

# Проверить .env файл
cat compose/.env
```

### Проблема: Бэкап не выполняется

**Решение**:
```bash
# Проверить статус timer
sudo systemctl status homelab-backup.timer

# Проверить логи
journalctl -u homelab-backup.service -n 50

# Проверить RESTIC_REPO
source compose/.env
echo $RESTIC_REPO

# Проверить монтирование backup диска
df -h | grep backup
```

Дополнительная информация в `06_troubleshooting.md`.
