# Social Checker

Скрипт для проверки доступности соцсетей, мессенджеров и видеохостингов с сервера.

## Возможности

- Проверка 40+ мировых сервисов
- Соцсети, мессенджеры, видеохостинги
- Цветной вывод на русском
- Вывод в JSON для автоматизации
- Фильтры: только доступные / только заблокированные
- Установка одной командой

## Установка

### Способ 1: одной командой

    curl -fsSL https://raw.githubusercontent.com/elifecomp/social-checker/main/install.sh | bash

### Способ 2: вручную

    git clone https://github.com/elifecomp/social-checker.git
    cd social-checker
    chmod +x check_socials.sh
    ./check_socials.sh

## Использование

    social-checker              # полная проверка
    social-checker --available  # только доступные
    social-checker --blocked    # только заблокированные
    social-checker --json       # JSON-вывод
    social-checker --timeout 5  # изменить таймаут
    social-checker --help       # справка

## Пример вывода

    =========================================
      SOCIAL CHECKER v1.0.0
    =========================================
    Дата: 2026-09-19 14:30:00

    Telegram - ДОСТУПЕН | Пинг: 43ms | [Мессенджер]
    Instagram - НЕДОСТУПЕН | [Соцсеть]
    YouTube - ДОСТУПЕН | Пинг: 65ms | [Видео]

    =========================================
    Доступно:    25
    Недоступно:  15
    Всего:       40
    =========================================

## Что проверяется

- Соцсети: Facebook, Instagram, X, Reddit, VK, OK, Pinterest, LinkedIn, Snapchat, Threads, Bluesky, Mastodon, Tumblr, Weibo, Douyin
- Мессенджеры: WhatsApp, Telegram, WeChat, Signal, Viber, Line, KakaoTalk, Discord, MAX, imo, BiP
- Видео: YouTube, TikTok, Twitch, Vimeo, Rutube, VK Video, Dzen, Netflix

## Важно

- Скрипт проверяет главный домен сервиса
- Результат зависит от того, откуда запускается скрипт
- Для точной диагностики используйте dig, traceroute, mtr

## Лицензия

MIT
