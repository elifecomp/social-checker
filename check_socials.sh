#!/usr/bin/env bash
# Social Checker v2.0 — проверка доступности популярных сервисов

VERSION="2.0.0"

# ---------- Список сервисов (без российских) ----------
SERVICES=(
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

# ---------- Параметры по умолчанию ----------
JSON_OUTPUT=false
ONLY_AVAILABLE=false
ONLY_BLOCKED=false
IPV4_ONLY=false
USE_COLOR=true
CATEGORY_FILTER=""
TIMEOUT=10
RETRIES=1
JOBS=10
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

usage() {
    cat <<EOF
Social Checker v$VERSION
Использование: $0 [опции]

  --json            Вывод в JSON
  --available       Только доступные (включая ограниченные)
  --blocked         Только недоступные / подозрительные / с ошибкой
  --category NAME   Фильтр: Соцсеть | Мессенджер | Видео | ИИ
  --timeout N       Общий таймаут запроса, сек (по умолчанию $TIMEOUT)
  --retries N       Повторные попытки при сбое (по умолчанию $RETRIES)
  --jobs N          Параллельных проверок (по умолчанию $JOBS)
  -4, --ipv4        Проверять только по IPv4
  --no-color        Без цветов
  -v, --version     Версия
  -h, --help        Справка
EOF
}

is_uint() { [[ "$1" =~ ^[0-9]+$ ]]; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_OUTPUT=true; shift ;;
        --available) ONLY_AVAILABLE=true; shift ;;
        --blocked) ONLY_BLOCKED=true; shift ;;
        --category) CATEGORY_FILTER="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --retries) RETRIES="$2"; shift 2 ;;
        --jobs) JOBS="$2"; shift 2 ;;
        -4|--ipv4) IPV4_ONLY=true; shift ;;
        --no-color) USE_COLOR=false; shift ;;
        -v|--version) echo "Social Checker v$VERSION"; exit 0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Неизвестный флаг: $1"; usage; exit 1 ;;
    esac
done

for v in TIMEOUT RETRIES JOBS; do
    if ! is_uint "${!v}" || [[ "${!v}" -lt 1 && "$v" != "RETRIES" ]]; then
        echo "Ошибка: значение для $v должно быть целым числом (>=1)."
        exit 1
    fi
done

if [[ "$ONLY_AVAILABLE" == true && "$ONLY_BLOCKED" == true ]]; then
    echo "Ошибка: --available и --blocked нельзя использовать вместе."
    exit 1
fi

# ---------- Цвета ----------
if [[ "$USE_COLOR" == true && -t 1 && "$JSON_OUTPUT" == false ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; NC=""
fi

for cmd in curl awk; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Ошибка: не найдена команда '$cmd'." >&2
        exit 1
    fi
done

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

CONNECT_TIMEOUT=$(( TIMEOUT < 5 ? TIMEOUT : 5 ))
CURL_OPTS=(-o /dev/null -s -L --max-redirs 5 -A "$UA"
           --connect-timeout "$CONNECT_TIMEOUT" --max-time "$TIMEOUT")
[[ "$IPV4_ONLY" == true ]] && CURL_OPTS+=(-4)

PRIV_RE='^(0\.0\.0\.0|127\.|10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2[0-9]|3[01])\.|::1|::$|f[cd][0-9a-f]{2}:)'

# ---------- Вспомогательные функции ----------
ms() { awk -v a="${1:-0}" -v b="${2:-0}" 'BEGIN{d=(a-b)*1000; if(d<0)d=0; printf "%.0f", d}'; }
is_zero() { awk -v v="${1:-0}" 'BEGIN{exit !(v+0==0)}'; }

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

# Контрольная проверка: есть ли вообще интернет
check_internet() {
    local u code
    for u in https://www.cloudflare.com https://www.apple.com https://www.microsoft.com; do
        code=$(curl -o /dev/null -s -L --connect-timeout 5 --max-time 8 \
               -w "%{http_code}" "$u" 2>/dev/null)
        [[ -n "$code" && "$code" != "000" ]] && return 0
    done
    return 1
}

# Проверка одного сервиса. Результат пишется в файл $WORKDIR/<idx>
check_service() {
    local idx="$1" name="$2" domain="$3" category="$4"
    local out rc attempt=0
    local code="000" t_dns=0 t_conn=0 t_tls=0 t_ttfb=0 ip="" url=""

    while (( attempt <= RETRIES )); do
        out=$(curl "${CURL_OPTS[@]}" \
            -w "%{http_code}|%{time_namelookup}|%{time_connect}|%{time_appconnect}|%{time_starttransfer}|%{remote_ip}|%{url_effective}" \
            "https://$domain" 2>/dev/null)
        rc=$?
        IFS='|' read -r code t_dns t_conn t_tls t_ttfb ip url <<< "$out"
        code="${code:-000}"
        # повторяем только при сбое сети, 5xx или 429
        if (( rc == 0 )) && [[ ! "$code" =~ ^(5[0-9][0-9]|429)$ ]]; then break; fi
        attempt=$((attempt + 1))
        (( attempt <= RETRIES )) && sleep 0.5
    done

    local status="" reason=""

    if [[ -n "$ip" && "$ip" =~ $PRIV_RE ]]; then
        status="blocked"
        reason="DNS-подмена: домен указывает на локальный/нулевой адрес ($ip)"
    elif (( rc == 0 )); then
        case "$code" in
            2??|3??) status="available" ;;
            451) status="blocked"; reason="HTTP 451 — недоступно по юридическим причинам" ;;
            403) status="limited"; reason="сервер отвечает, но отказывает в доступе (403: гео-ограничение или антибот)" ;;
            429) status="limited"; reason="сервер отвечает, но ограничивает частоту запросов (429)" ;;
            4??) status="available"; reason="сервер отвечает (HTTP $code)" ;;
            5??) status="error"; reason="ошибка на стороне сервера (HTTP $code)" ;;
            *)   status="error"; reason="неожиданный HTTP-код: $code" ;;
        esac

        # Проверка редиректа на «чужой» домен (возможная страница-заглушка)
        if [[ "$status" == "available" && "$code" =~ ^[23] ]]; then
            local host="${url#*://}"; host="${host%%/*}"; host="${host%%:*}"
            local -a parts
            IFS=. read -ra parts <<< "$domain"
            local n=${#parts[@]}
            local label="${parts[$((n - 2))]}"
            if [[ -n "$host" && "$host" != *"$label"* ]]; then
                status="suspicious"
                reason="редирект на посторонний домен: $host"
            fi
        fi
    else
        status="blocked"
        case "$rc" in
            6)  reason="DNS не резолвится (вероятна DNS-блокировка)" ;;
            7)  reason="соединение отклонено (connection refused)" ;;
            28)
                if is_zero "$t_conn"; then
                    reason="таймаут на этапе TCP (вероятен дроп пакетов)"
                elif is_zero "$t_tls"; then
                    reason="таймаут на TLS-рукопожатии (вероятна блокировка по SNI/DPI)"
                else
                    reason="таймаут ожидания ответа"
                fi ;;
            35|51|58|59|66|77|80|90)
                reason="ошибка TLS (вероятна блокировка по SNI/DPI)" ;;
            60) reason="сертификат не прошёл проверку (возможна подмена/MITM)" ;;
            52|56) reason="соединение сброшено (connection reset)" ;;
            47) status="error"; reason="слишком много редиректов" ;;
            *)  reason="сбой curl (код $rc)" ;;
        esac
    fi

    local dns tcp tls ttfb total
    dns=$(ms "$t_dns" 0)
    tcp=$(ms "$t_conn" "$t_dns")
    tls=$(ms "$t_tls" "$t_conn")
    ttfb=$(ms "$t_ttfb" "$t_tls")
    total=$(ms "$t_ttfb" 0)

    printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
        "$name" "$domain" "$category" "$status" "$code" \
        "$dns" "$tcp" "$tls" "$ttfb" "$total" "${ip:--}" "$reason" > "$WORKDIR/$idx"
}

# ---------- Заголовок ----------
if [[ "$JSON_OUTPUT" == false ]]; then
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  SOCIAL CHECKER v$VERSION${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Хост: $(hostname)"
    echo ""
fi

# ---------- Контроль интернета ----------
if ! check_internet; then
    echo -e "${RED}Нет доступа в интернет (контрольные сайты не отвечают). Проверка прервана,${NC}" >&2
    echo -e "${RED}иначе все сервисы ошибочно показались бы заблокированными.${NC}" >&2
    exit 2
fi

# ---------- Параллельная проверка ----------
idx=0
for service in "${SERVICES[@]}"; do
    IFS='|' read -r name domain category <<< "$service"
    if [[ -n "$CATEGORY_FILTER" && "$category" != "$CATEGORY_FILTER" ]]; then
        continue
    fi
    idx=$((idx + 1))
    check_service "$(printf '%03d' "$idx")" "$name" "$domain" "$category" &
    if (( idx % JOBS == 0 )); then wait; fi
done
wait

if (( idx == 0 )); then
    echo "Нет сервисов для проверки (проверьте --category)." >&2
    exit 1
fi

# ---------- Вывод ----------
total=0; n_available=0; n_limited=0; n_suspicious=0; n_error=0; n_blocked=0
sum_ttfb=0; cnt_ttfb=0
json_items=()

for f in "$WORKDIR"/*; do
    [[ -f "$f" ]] || continue
    IFS='|' read -r name domain category status code dns tcp tls ttfb tot ip reason < "$f"
    total=$((total + 1))

    case "$status" in
        available)  n_available=$((n_available + 1)) ;;
        limited)    n_limited=$((n_limited + 1)) ;;
        suspicious) n_suspicious=$((n_suspicious + 1)) ;;
        error)      n_error=$((n_error + 1)) ;;
        blocked)    n_blocked=$((n_blocked + 1)) ;;
    esac

    if [[ "$status" == "available" || "$status" == "limited" ]]; then
        reachable=true
        sum_ttfb=$((sum_ttfb + tot)); cnt_ttfb=$((cnt_ttfb + 1))
    else
        reachable=false
    fi

    if [[ "$ONLY_AVAILABLE" == true && "$reachable" != true ]]; then continue; fi
    if [[ "$ONLY_BLOCKED" == true && "$reachable" == true ]]; then continue; fi

    if [[ "$JSON_OUTPUT" == true ]]; then
        json_items+=("{\"name\":\"$(json_escape "$name")\",\"domain\":\"$domain\",\"category\":\"$(json_escape "$category")\",\"status\":\"$status\",\"http_code\":\"$code\",\"ip\":\"$ip\",\"dns_ms\":$dns,\"tcp_ms\":$tcp,\"tls_ms\":$tls,\"ttfb_ms\":$ttfb,\"total_ms\":$tot,\"reason\":\"$(json_escape "$reason")\"}")
        continue
    fi

    timing="DNS ${dns}ms · TCP ${tcp}ms · TLS ${tls}ms · ответ ${ttfb}ms"
    case "$status" in
        available)
            echo -e "${GREEN}✅ $name${NC} — ДОСТУПЕН | HTTP $code | $timing | ${BLUE}[$category]${NC}" ;;
        limited)
            echo -e "${YELLOW}🟡 $name${NC} — ОГРАНИЧЕН | $reason | ${BLUE}[$category]${NC}" ;;
        suspicious)
            echo -e "${YELLOW}⚠️  $name${NC} — ПОДОЗРИТЕЛЬНО | $reason | ${BLUE}[$category]${NC}" ;;
        error)
            echo -e "${YELLOW}🔧 $name${NC} — ОШИБКА | $reason | ${BLUE}[$category]${NC}" ;;
        blocked)
            echo -e "${RED}❌ $name${NC} — НЕДОСТУПЕН | $reason | ${BLUE}[$category]${NC}" ;;
    esac
done

avg_ttfb=0
(( cnt_ttfb > 0 )) && avg_ttfb=$((sum_ttfb / cnt_ttfb))

if [[ "$JSON_OUTPUT" == true ]]; then
    echo "{"
    echo "  \"host\": \"$(json_escape "$(hostname)")\","
    echo "  \"date\": \"$(date '+%Y-%m-%dT%H:%M:%S%z')\","
    echo "  \"version\": \"$VERSION\","
    echo "  \"total\": $total,"
    echo "  \"available\": $n_available,"
    echo "  \"limited\": $n_limited,"
    echo "  \"suspicious\": $n_suspicious,"
    echo "  \"error\": $n_error,"
    echo "  \"blocked\": $n_blocked,"
    echo "  \"avg_response_ms\": $avg_ttfb,"
    echo "  \"services\": ["
    last=$(( ${#json_items[@]} - 1 ))
    for i in "${!json_items[@]}"; do
        if (( i == last )); then echo "    ${json_items[$i]}"; else echo "    ${json_items[$i]},"; fi
    done
    echo "  ]"
    echo "}"
    exit 0
fi

if [[ "$ONLY_BLOCKED" == true && $((n_blocked + n_suspicious + n_error)) -eq 0 ]]; then
    echo -e "${GREEN}Недоступных сервисов не найдено — все отвечают!${NC}"
fi

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}Доступно:${NC}       $n_available"
echo -e "${YELLOW}Ограничено:${NC}     $n_limited"
echo -e "${YELLOW}Подозрительно:${NC}  $n_suspicious"
echo -e "${YELLOW}Ошибки сервера:${NC} $n_error"
echo -e "${RED}Недоступно:${NC}     $n_blocked"
echo -e "${CYAN}Всего:${NC}          $total"
echo -e "Средний отклик: ${avg_ttfb}ms"
echo -e "${CYAN}=========================================${NC}"
