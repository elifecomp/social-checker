#!/bin/bash

VERSION="1.1.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

for cmd in curl awk; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Ошибка: не найдена команда '$cmd'.${NC}"
        exit 1
    fi
done

services=(
    # === СОЦСЕТИ ===
    "Facebook|facebook.com|Соцсеть"
    "Instagram|instagram.com|Соцсеть"
    "X (Twitter)|x.com|Соцсеть"
    "Reddit|reddit.com|Соцсеть"
    "Pinterest|pinterest.com|Соцсеть"
    "LinkedIn|linkedin.com|Соцсеть"
    "Snapchat|snapchat.com|Соцсеть"
    "Threads|threads.net|Соцсеть"
    "Bluesky|bsky.app|Соцсеть"
    "Mastodon|mastodon.social|Соцсеть"
    "Tumblr|tumblr.com|Соцсеть"
    "Douyin|douyin.com|Соцсеть"
    "Weibo|weibo.com|Соцсеть"
    "Zhihu|zhihu.com|Соцсеть"
    "Nextdoor|nextdoor.com|Соцсеть"
    "Patreon|patreon.com|Соцсеть"

    # === МЕССЕНДЖЕРЫ ===
    "WhatsApp|whatsapp.com|Мессенджер"
    "Telegram|telegram.org|Мессенджер"
    "WeChat|wechat.com|Мессенджер"
    "Messenger|messenger.com|Мессенджер"
    "Discord|discord.com|Мессенджер"
    "Signal|signal.org|Мессенджер"
    "Viber|viber.com|Мессенджер"
    "Line|line.me|Мессенджер"
    "KakaoTalk|kakao.com|Мессенджер"
    "imo|imo.im|Мессенджер"
    "BiP|bip.com|Мессенджер"
    "GroupMe|groupme.com|Мессенджер"

    # === ВИДЕОХОСТИНГИ ===
    "YouTube|youtube.com|Видео"
    "TikTok|tiktok.com|Видео"
    "Twitch|twitch.tv|Видео"
    "Vimeo|vimeo.com|Видео"
    "Dailymotion|dailymotion.com|Видео"
    "Netflix|netflix.com|Видео"
    "Bilibili|bilibili.com|Видео"
    "Wistia|wistia.com|Видео"

    # === ИИ-ПРИЛОЖЕНИЯ ===
    "ChatGPT|chatgpt.com|ИИ"
    "OpenAI|openai.com|ИИ"
    "Google Gemini|gemini.google.com|ИИ"
    "Claude (Anthropic)|claude.ai|ИИ"
    "Microsoft Copilot|copilot.microsoft.com|ИИ"
    "Midjourney|midjourney.com|ИИ"
    "Stable Diffusion|stability.ai|ИИ"
    "DeepSeek|deepseek.com|ИИ"
    "ElevenLabs|elevenlabs.io|ИИ"
    "Perplexity AI|perplexity.ai|ИИ"
    "Cursor|cursor.com|ИИ"
    "Hugging Face|huggingface.co|ИИ"
    "Mistral AI|mistral.ai|ИИ"
    "Grok (xAI)|x.ai|ИИ"
    "Meta AI|meta.ai|ИИ"
)

JSON_OUTPUT=false
ONLY_AVAILABLE=false
ONLY_BLOCKED=false
TIMEOUT=5

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_OUTPUT=true; shift ;;
        --available) ONLY_AVAILABLE=true; shift ;;
        --blocked) ONLY_BLOCKED=true; shift ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        -v|--version) echo "Social Checker v$VERSION"; exit 0 ;;
        -h|--help)
            echo "Social Checker v$VERSION"
            echo "Использование: $0 [опции]"
            echo "  --json         Вывод в JSON"
            echo "  --available    Только доступные"
            echo "  --blocked      Только недоступные"
            echo "  --timeout N    Таймаут в секундах"
            exit 0
            ;;
        *) echo "Неизвестный флаг: $1"; exit 1 ;;
    esac
done

if [[ "$JSON_OUTPUT" == false ]]; then
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  SOCIAL CHECKER v$VERSION${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "Хост: $(hostname)"
    echo ""
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Проверяем все сервисы одновременно (быстро)
i=0
for service in "${services[@]}"; do
    i=$((i + 1))
    (
        IFS='|' read -r name domain category <<< "$service"
        response=$(curl -o /dev/null -s -L -A "Mozilla/5.0" -w "%{http_code}|%{time_total}" \
            --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" "https://$domain" 2>/dev/null)
        http_code=$(echo "$response" | cut -d'|' -f1)
        time_total=$(echo "$response" | cut -d'|' -f2)
        time_ms=$(echo "$time_total" | awk '{printf "%.0f", $1 * 1000}')

        # Любой ответ от сервера = доступен, нет ответа = недоступен
        if [[ -z "$http_code" || "$http_code" == "000" ]]; then
            status="blocked"
        else
            status="available"
        fi
        echo "$name|$domain|$category|$status|$http_code|$time_ms" > "$tmpdir/$(printf '%03d' "$i")"
    ) &
done
wait

json_items=()
total=0
available=0
blocked=0

for f in "$tmpdir"/*; do
    IFS='|' read -r name domain category status http_code time_ms < "$f"
    total=$((total + 1))
    if [[ "$status" == "available" ]]; then
        available=$((available + 1))
    else
        blocked=$((blocked + 1))
    fi

    if [[ "$JSON_OUTPUT" == true ]]; then
        json_items+=("{\"name\":\"$name\",\"domain\":\"$domain\",\"category\":\"$category\",\"status\":\"$status\",\"http_code\":\"$http_code\",\"ping_ms\":$time_ms}")
    else
        if [[ "$ONLY_AVAILABLE" == true && "$status" != "available" ]]; then continue; fi
        if [[ "$ONLY_BLOCKED" == true && "$status" != "blocked" ]]; then continue; fi

        case "$status" in
            available)
                echo -e "${GREEN}✅ $name${NC} — ДОСТУПЕН"
                ;;
            blocked)
                echo -e "${RED}❌ $name${NC} — НЕДОСТУПЕН"
                ;;
        esac
    fi
done

if [[ "$ONLY_BLOCKED" == true && "$blocked" -eq 0 ]]; then
    echo -e "${GREEN}Заблокированных сервисов не найдено — все доступны!${NC}"
    echo ""
fi

if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{"
    echo "  \"host\": \"$(hostname)\","
    echo "  \"date\": \"$(date -Iseconds)\","
    echo "  \"version\": \"$VERSION\","
    echo "  \"total\": $total,"
    echo "  \"available\": $available,"
    echo "  \"blocked\": $blocked,"
    echo "  \"services\": ["
    for i in "${!json_items[@]}"; do
        if [[ $i -eq $((${#json_items[@]} - 1)) ]]; then
            echo "    ${json_items[$i]}"
        else
            echo "    ${json_items[$i]},"
        fi
    done
    echo "  ]"
    echo "}"
    exit 0
fi

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}Доступно:${NC}    $available"
echo -e "${RED}Недоступно:${NC}  $blocked"
echo -e "${YELLOW}Всего:${NC}       $total"
echo -e "${CYAN}=========================================${NC}"
