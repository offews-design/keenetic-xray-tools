# Keenetic Xray Tools

Набор скриптов для быстрой настройки Xray на роутерах Keenetic с Entware.

## Точные модели Keenetic и Netcraze

Для новых установок ориентируйся не только на название модели, а на точный код ревизии:

- `KN-xxxx` для Keenetic.
- `NC-xxxx` для Netcraze.

Перед покупкой проси у клиента или продавца фото наклейки снизу роутера либо карточки товара, где указан этот код.

Точно подходят для покупки:

```text
Keenetic Hopper    KN-3811  - основной вариант
Keenetic Hopper SE KN-3812  - основной вариант с запасом
Keenetic Giga/Hero KN-1012  - вариант с запасом, название зависит от рынка
Keenetic Peak      KN-2710  - мощный вариант
Keenetic Ultra SE  KN-2510  - мощный вариант
Keenetic Ultra     KN-1811  - мощный вариант
```

Точно подходят из Netcraze:

```text
Netcraze Hopper  NC-3811  - основной вариант
Netcraze Giga    NC-1012  - вариант с запасом
Netcraze Ultra   NC-1812  - мощный вариант
Netcraze Hero 5G NC-4110  - мощный вариант с 5G/LTE WAN
```

Можно использовать, если уже есть у клиента:

```text
Keenetic Hopper KN-3810  - рабочий вариант, но KN-3811/3812 предпочтительнее
Keenetic Giga   KN-1010  - старый рабочий вариант, лучше с USB-флешкой
Keenetic Giga   KN-1011  - старый рабочий вариант, лучше с USB-флешкой
Keenetic Ultra  KN-1810  - старый рабочий вариант, лучше с USB-флешкой
Keenetic Giant  KN-2610  - рабочий вариант
Keenetic Viva   KN-1913  - только для умеренной нагрузки
Netcraze Viva   NC-1913  - только для умеренной нагрузки
```

Покупать только после отдельной проверки задачи:

```text
Keenetic Hero 4G   KN-2310 / KN-2311
Keenetic Hopper DSL KN-3610
Netcraze Hopper DSL NC-3611
```

Не брать как основной вариант для Xray/YouTube:

```text
Keenetic Start
Keenetic Lite
Keenetic City
Keenetic Air
Keenetic 4G KN-1210 / KN-1211 / KN-1213
Keenetic Extra KN-1714
Netcraze 4G NC-1213
Netcraze Carrier NC-1721
Speedster / Speedster DSL / Speedster 4G+
старые MIPS-модели
модели с 128/256 MB RAM
модели без USB
модели без OPKG/Entware
модели без точного KN/NC-кода в объявлении
```

Минимальные требования:

```text
CPU: ARM/ARM64, желательно 2 ядра от 1 GHz
RAM: 512 MB
Entware/OPKG: да
USB-порт: да
SSH: да
```

Если в объявлении указано только `Hopper`, `Hero`, `Giga`, `Ultra`, `Peak` или `Netcraze`, но нет точного `KN-xxxx` / `NC-xxxx`, решение о покупке не принимаем до уточнения ревизии.

Старые или слабые модели могут запускать OPKG, но для YouTube/Telegram/Instagram через Xray часто не хватает производительности.

Проверочные источники:

- Keenetic OPKG: `https://help.keenetic.com/hc/ru/articles/360000948719-OPKG`
- Keenetic OPKG во встроенную память: `https://help.keenetic.com/hc/ru/articles/360021888880`
- Netcraze Hopper NC-3811: `https://netcraze.ru/ru/netcraze-hopper`
- Netcraze Giga NC-1012 OPKG: `https://support.netcraze.ru/giga/nc-1012/ru/18481-opkg.html`
- Netcraze Ultra NC-1812: `https://netcraze.ru/ru/netcraze-ultra`
- Netcraze Hero 5G NC-4110: `https://support.netcraze.ru/hero-5g/nc-4110/ru/25475-getting-started.html`

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

## Где выполнять команды

Все команды из этого README выполняются **на роутере Keenetic в SSH/Entware-консоли**.

Команды не нужно выполнять в Windows PowerShell, CMD или на обычном компьютере.

Перед запуском скриптов проверь, что ты находишься на роутере и Entware доступен:

```sh
ls /opt
opkg --version
```

Если `/opt` отсутствует или `opkg` не найден, сначала нужно включить/установить Entware в веб-интерфейсе Keenetic.

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
