#!/bin/bash

set -e

REPO_RAW="https://raw.githubusercontent.com/elifecomp/social-checker/main"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="social-checker"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  Установка Social Checker${NC}"
echo -e "${CYAN}=========================================${NC}"

if ! command -v curl &>/dev/null; then
    echo -e "${RED}Ошибка: нужен curl${NC}"
    exit 1
fi

echo "→ Скачиваю check_socials.sh..."
TMP_FILE=$(mktemp)
curl -fsSL "$REPO_RAW/check_socials.sh" -o "$TMP_FILE"

echo "→ Устанавливаю в $INSTALL_DIR/$SCRIPT_NAME..."
if [[ -w "$INSTALL_DIR" ]]; then
    mv "$TMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
else
    sudo mv "$TMP_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
fi
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo -e "${GREEN}✅ Установлено!${NC}"
echo ""
echo "Запусти:"
echo -e "  ${CYAN}social-checker${NC}              # полная проверка"
echo -e "  ${CYAN}social-checker --available${NC}  # только доступные"
echo -e "  ${CYAN}social-checker --blocked${NC}    # только заблокированные"
echo -e "  ${CYAN}social-checker --json${NC}       # вывод в JSON"
