#!/bin/bash

# Проверяем, что скрипт запущен от root
if [ "$EUID" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт от имени root (sudo)"
    exit 1
fi

# Функция для сохранения пакетов
save_packages() {
    BACKUP_DIR="./packages_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Копируем sources.list и дополнительные источники
    cp /etc/apt/sources.list "$BACKUP_DIR/sources.list"
    if [ -d /etc/apt/sources.list.d ]; then
        cp -r /etc/apt/sources.list.d "$BACKUP_DIR/"
    fi

    # Сохраняем список установленных пакетов
    dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"

    # Архивируем
    tar -czf "packages_backup_$(date +%Y%m%d_%H%M%S).tar.gz" "$BACKUP_DIR"

    # Удаляем временную директорию
    rm -rf "$BACKUP_DIR"

    echo "Сохранение завершено. Файл backup создан в текущей директории."
}

# Функция для восстановления пакетов
restore_packages() {
    echo "Введите полный путь к файлу backup (.tar.gz):"
    read BACKUP_FILE

    # Проверяем существование файла
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Файл $BACKUP_FILE не найден"
        return 1
    fi

    # Создаем временную директорию
    TEMP_DIR=$(mktemp -d)

    # Распаковываем архив
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

    # Копируем sources.list
    cp "$TEMP_DIR"/*/sources.list /etc/apt/sources.list
    if [ -d "$TEMP_DIR"/*/sources.list.d ]; then
        cp -r "$TEMP_DIR"/*/sources.list.d/* /etc/apt/sources.list.d/
    fi

    # Обновляем списки пакетов
    apt update

    # Устанавливаем пакеты
    dpkg --set-selections < "$TEMP_DIR"/*/installed-packages.txt
    apt-get dselect-upgrade -y

    # Убираем временную директорию
    rm -rf "$TEMP_DIR"

    echo "Восстановление пакетов завершено!"
}

# Основное меню
while true; do
    echo "Выберите действие:"
    echo "1. Сохранить пакеты в backup"
    echo "2. Восстановить пакеты из backup"
    echo "3. Выйти"
    echo -n "Введите номер (1-3): "
    read CHOICE

    case $CHOICE in
        1)
            save_packages
            ;;
        2)
            restore_packages
            ;;
        3)
            echo "Выход..."
            exit 0
            ;;
        *)
            echo "Неверный выбор. Пожалуйста, введите число от 1 до 3."
            ;;
    esac

    echo -n "Нажмите Enter для продолжения..."
    read
    clear
done
