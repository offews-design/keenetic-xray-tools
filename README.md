# Keenetic Xray Tools

Набор скриптов для быстрой настройки Xray на роутерах Keenetic с Entware.

## Рекомендуемые модели Keenetic

Для новых установок лучше использовать модели с запасом по CPU/RAM и поддержкой Entware/OPKG.

Основной рекомендуемый вариант:

```text
Keenetic Hopper KN-3811
```

Также подходят как варианты с запасом:

```text
Keenetic Hero KN-1012
Keenetic Giga KN-1012
Keenetic Ultra
Keenetic Peak
```

Минимальные требования:

```text
CPU: ARM/ARM64, желательно 2 ядра от 1 GHz
RAM: 512 MB
Entware/OPKG: да
USB-порт: да
SSH: да
```

Не рекомендуется брать для новых установок:

```text
Keenetic Start
Keenetic Lite
Keenetic City
Keenetic Air
старые MIPS-модели
модели с 128/256 MB RAM
```

Старые или слабые модели могут работать, но для YouTube/Telegram/Instagram через Xray часто не хватает производительности.

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
- USB-флешка или USB SSD под Entware.

Стандартные пути:

```sh
/opt/bin/xray
/opt/etc/xray/config.json
/opt/etc/init.d/S24xray
```

## Флешка для Entware

Для массовой настройки рекомендуется использовать USB-накопитель:

```text
USB 3.0 флешка 16-32 GB
лучше: USB SSD
файловая система: ext4
разметка: MBR
один primary-раздел на весь накопитель
метка: ENTWARE
```

Зачем нужна флешка:

- Entware устанавливается в `/opt`.
- Xray и конфиги лежат в `/opt`.
- Проще обновлять и обслуживать клиентов.
- Меньше риска упереться во встроенную память роутера.

### Безопасный способ

Лучше всего подготовить флешку через веб-интерфейс Keenetic:

```text
1. Вставить флешку в USB-порт роутера.
2. Открыть веб-интерфейс Keenetic.
3. Найти раздел USB-накопителей.
4. Отформатировать накопитель в ext4.
5. Установить/включить компонент OPKG/Entware.
6. Выбрать этот USB-накопитель для OPKG.
7. Дождаться установки Entware.
8. Проверить по SSH, что появилась папка /opt.
```

### Скрипт подготовки флешки

Если нужно подготовить флешку вручную по SSH, можно использовать:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/prepare-usb.sh -o /tmp/prepare-usb.sh
sh /tmp/prepare-usb.sh --list
sh /tmp/prepare-usb.sh --auto ENTWARE
```

Внимание: скрипт полностью стирает выбранный USB-накопитель.

Если `--auto` отказывается работать, значит найдено несколько USB/removable устройств. Тогда выбери флешку вручную:

```sh
sh /tmp/prepare-usb.sh /dev/sda ENTWARE
```

Скрипт проверяет, что устройство похоже на USB/removable, и отказывается форматировать устройство, с которого смонтированы `/` или `/opt`.

Все равно перед запуском проверь список устройств:

```sh
lsblk
```

Не запускай ручной режим, если не уверен, что `/dev/sda` - это именно флешка.

### Подготовка флешки на Windows

Если флешку нужно подготовить заранее на Windows, используй программу, которая умеет создавать ext4-разделы:

```text
MiniTool Partition Wizard
AOMEI Partition Assistant
DiskGenius
Rufus
```

Рекомендуемые параметры:

```text
Partition table: MBR
Partition type: Primary
Filesystem: ext4
Label: ENTWARE
Size: весь накопитель
```

Обычное форматирование Windows в `FAT32`, `exFAT` или `NTFS` для Entware лучше не использовать.

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

## Backup

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/backup.sh | sh
```

Backup сохраняется в:

```sh
/opt/root/xray-backups/
```

## Repair

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/repair.sh | sh
```

Repair проверяет:

- смонтирован ли `/opt`;
- есть ли `/opt/bin/xray`;
- валиден ли `/opt/etc/xray/config.json`;
- есть ли init-скрипт `/opt/etc/init.d/S24xray`;
- запущен ли процесс Xray;
- работает ли локальный SOCKS `127.0.0.1:10808`;
- CPU/RAM.

Если Xray отсутствует, `repair.sh` попробует скачать подходящую версию под архитектуру роутера.

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
