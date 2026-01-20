#!/usr/bin/env bash
# =============================================================================
# Deploy Homepage Configuration
# =============================================================================
# Копирует конфиги Homepage из репозитория в /srv/data/homepage/config
# Используется при деплое для применения изменений конфигов
# =============================================================================

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логирование функций
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Конфигурация
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_SOURCE="${PROJECT_ROOT}/compose/homepage/config"
CONFIG_TARGET="/srv/data/homepage/config"

# =============================================================================
# Функции
# =============================================================================

check_source_dir() {
    log_info "Проверка исходной директории: ${CONFIG_SOURCE}"

    if [[ ! -d "${CONFIG_SOURCE}" ]]; then
        log_error "Директория с конфигами не найдена: ${CONFIG_SOURCE}"
        exit 1
    fi

    # Проверяем наличие YAML файлов
    if ! ls "${CONFIG_SOURCE}"/*.yaml &> /dev/null; then
        log_error "В директории нет YAML файлов: ${CONFIG_SOURCE}"
        exit 1
    fi

    log_success "Исходная директория OK"
}

create_target_dir() {
    log_info "Проверка целевой директории: ${CONFIG_TARGET}"

    if [[ ! -d "${CONFIG_TARGET}" ]]; then
        log_warn "Целевая директория не существует, создаём..."
        sudo mkdir -p "${CONFIG_TARGET}"
        sudo chown -R $(whoami):$(whoami) "${CONFIG_TARGET}"
    fi

    log_success "Целевая директория OK"
}

backup_existing_config() {
    log_info "Проверка существующих конфигов..."

    if [[ -d "${CONFIG_TARGET}" ]] && ls "${CONFIG_TARGET}"/*.yaml &> /dev/null; then
        BACKUP_DIR="${CONFIG_TARGET}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Найдены существующие конфиги, создаём бэкап: ${BACKUP_DIR}"
        sudo cp -r "${CONFIG_TARGET}" "${BACKUP_DIR}"
        log_success "Бэкап создан"
    else
        log_info "Существующих конфигов нет, бэкап не нужен"
    fi
}

deploy_configs() {
    log_info "Копирование конфигов из репозитория..."

    # Копируем все YAML файлы
    for config_file in "${CONFIG_SOURCE}"/*.yaml; do
        filename=$(basename "${config_file}")
        log_info "  Копирую: ${filename}"

        # Используем sudo для записи в /srv/data
        sudo cp "${config_file}" "${CONFIG_TARGET}/${filename}"

        # Устанавливаем права
        sudo chmod 644 "${CONFIG_TARGET}/${filename}"
    done

    log_success "Конфиги скопированы"
}

verify_deployment() {
    log_info "Проверка деплоя..."

    # Проверяем что файлы скопировались
    local file_count=$(ls "${CONFIG_TARGET}"/*.yaml 2>/dev/null | wc -l)
    if [[ ${file_count} -eq 0 ]]; then
        log_error "Конфиги не были скопированы!"
        exit 1
    fi

    log_success "Деплой завершён успешно (${file_count} файлов)"

    # Показываем список скопированных файлов
    echo ""
    log_info "Скопированные файлы:"
    ls -lh "${CONFIG_TARGET}"/*.yaml
}

show_summary() {
    echo ""
    log_success "=== Деплой Homepage конфигов завершён ==="
    echo ""
    echo "  Источник: ${CONFIG_SOURCE}"
    echo "  Цель:     ${CONFIG_TARGET}"
    echo ""
    echo "  Для применения изменений перезапустите Homepage:"
    echo "    docker compose -f compose/compose.yml restart homepage"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    log_info "=== Деплой Homepage конфигов ==="
    echo ""

    # Проверяем, что мы на сервере
    if [[ ! -d "/srv/data" ]]; then
        log_error "Директория /srv/data не найдена. Вы на сервере?"
        exit 1
    fi

    # Выполняем шаги деплоя
    check_source_dir
    create_target_dir
    backup_existing_config
    deploy_configs
    verify_deployment
    show_summary
}

# Запуск
main "$@"
