# Keenetic Xray Tools

Набор скриптов для быстрой настройки Xray на роутерах Keenetic с Entware.

Цель схемы:

- Telegram / YouTube / Instagram идут через VPN.
- Остальной трафик остается напрямую через провайдера.
- Для каждого клиента используется персональная VLESS-ссылка из 3x-ui.

## Требования

На роутере должны быть:

- Keenetic с поддержкой Entware/OPKG.
- Включенный SSH-доступ.
- Установленный Entware в `/opt`.
- Доступ роутера в интернет.

Стандартные пути:

```sh
/opt/bin/xray
/opt/etc/xray/config.json
/opt/etc/init.d/S24xray
```

## Установка

В 3x-ui создай отдельного клиента для Keenetic и скопируй его `vless://...` ссылку.

На роутере выполни:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/install.sh | sh -s -- 'vless://CLIENT_LINK'
```

Скрипт:

- проверит наличие Entware;
- установит Xray, если его нет;
- создаст `/opt/etc/xray/config.json`;
- добавит правила Xray для Telegram / YouTube / Instagram;
- оставит остальной трафик напрямую;
- создаст init-скрипт `/opt/etc/init.d/S24xray`;
- запустит Xray.

## Проверка

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
```

Проверка покажет:

- версию системы;
- наличие Entware;
- версию Xray;
- валидность конфига;
- запущен ли процесс Xray;
- локальные порты;
- тест через SOCKS `127.0.0.1:10808`;
- CPU/RAM.

## Удаление

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/uninstall.sh | sh
```

Скрипт остановит Xray и уберет временные firewall-цепочки, если они создавались.

Файлы Xray остаются на роутере для ручного восстановления:

```sh
/opt/bin/xray
/opt/etc/xray/config.json
/opt/etc/init.d/S24xray
```

## Прозрачный режим

По умолчанию скрипт не включает прозрачный перехват LAN-трафика.

Это сделано специально: firewall у Keenetic может отличаться между версиями KeeneticOS, и слепое включение `iptables redirect` может сломать интернет на роутере.

Сначала проверь, что Xray работает через локальный SOCKS:

```sh
127.0.0.1:10808
```

После проверки можно отдельно адаптировать прозрачный режим под конкретную модель/прошивку.

Заготовка:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh
```

Сейчас `transparent.sh` создает безопасный scaffold и не перенаправляет весь трафик автоматически.

## Какой профиль создавать в 3x-ui

Для Keenetic лучше начинать с совместимого профиля:

```text
Protocol: VLESS
Transport: TCP RAW
Security: REALITY
Flow: xtls-rprx-vision
Fingerprint: chrome
```

Если конкретный Keenetic поддерживает XHTTP, можно тестировать отдельный профиль:

```text
Protocol: VLESS
Transport: XHTTP
Security: REALITY
Flow: пусто
Fingerprint: qq
```

## Важно

- Не используй один общий UUID для всех клиентов.
- Для каждого Keenetic создавай отдельного клиента в 3x-ui.
- Не храни `vless://...` ссылки в репозитории.
- Перед массовым внедрением проверь скрипт на одном роутере.
- Если YouTube тормозит, сначала проверь CPU роутера и скорость, а не меняй сразу SNI/порт.

