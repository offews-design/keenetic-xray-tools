# Keenetic Xray Tools

Набор скриптов для быстрой настройки Xray на роутерах Keenetic с Entware.

```text
Для bridge-схемы желательно подключение от 50 Мбит/с.
Если меньше 30 Мбит/с, YouTube через bridge может работать только в 720p.
Для стабильного 1080p лучше 50-100 Мбит/с.
Для 4K или нескольких устройств лучше 100+ Мбит/с.
```

## Точные модели Keenetic и Netcraze

Для новых установок ориентируйся не только на название модели, а на точный код ревизии:

- `KN-xxxx` для Keenetic.
- `NC-xxxx` для Netcraze.


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

Не брать как основной вариант для Xray:

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
модели без точного KN/NC-кода
```

Минимальные требования:

```text
CPU: ARM/ARM64, желательно 2 ядра от 1 GHz
RAM: 512 MB
Entware/OPKG: да
USB-порт: да
SSH: да
```


Старые или слабые модели могут запускать OPKG, но для работы через Xray часто не хватает производительности.

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

Для настройки рекомендуется использовать USB-накопитель:

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

Если `--auto` отказывается работать, значит найдено несколько USB/removable устройств. Тогда выберите флешку вручную:

```sh
sh /tmp/prepare-usb.sh /dev/sda ENTWARE
```

Скрипт проверяет, что устройство похоже на USB/removable, и отказывается форматировать устройство, с которого смонтированы `/` или `/opt`.

Все равно перед запуском проверь список устройств:

```sh
lsblk
```

Не запускайте ручной режим, если не уверен, что `/dev/sda` - это именно флешка.

### Подготовка флешки на Windows

Если флешку нужно подготовить заранее на Windows, используйте программу, которая умеет создавать ext4-разделы, например:

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

Обычное форматирование Windows в `FAT32`, `exFAT` или `NTFS` для Entware не подходит.

## Установка

Нужна ссылка конфигурации в формате `vless://...`.

Сначала отключите старые transparent-правила, если они уже есть и включались:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- unblock-quic
```

Затем сохраните ссылку в переменную. Вставляйте ссылку одной строкой, без переносов внутри `pbk`, `sid` и других параметров:

```sh
VLESS='vless://CLIENT_LINK'
```

Установить или обновить Xray-конфиг:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/install.sh | sh -s -- "$VLESS"
```

Скрипт:

- проверит наличие Entware;
- использует существующий Xray, если он найден в `/opt/sbin/xray` или `/opt/bin/xray`;
- установит Xray, если его нет;
- сделает backup старых файлов в `/opt/root/xray-backups/`;
- создаст `/opt/etc/xray/config.json`;
- добавит правила Xray для Telegram / YouTube / Instagram;
- отправит остальной трафик через `direct` внутри Xray;
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

Успешный минимум:

```text
Configuration OK
xray run -config /opt/etc/xray/config.json
127.0.0.1:10808 LISTEN
0.0.0.0:12345 LISTEN
Connectivity: внешний IP
```

Если `12345` слушает `127.0.0.1`, исправьте старый конфиг(если он был):

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/fix-transparent-listen.sh | sh
```

## Тест скорости

Сначала проверьте скорость без Xray:

```sh
curl -L -o /dev/null https://speed.cloudflare.com/__down?bytes=10000000
```

Потом проверьте скорость через локальный SOCKS Xray:

```sh
curl -L --socks5-hostname 127.0.0.1:10808 -o /dev/null https://speed.cloudflare.com/__down?bytes=50000000
```

Сравните значения `Average Speed`:

```text
1 MB/s  примерно 8 Мбит/с
2 MB/s  примерно 16 Мбит/с
3 MB/s  примерно 24 Мбит/с
```

Если CPU низкий, но скорость через SOCKS заметно ниже прямой скорости, ограничение в профиле/маршруте `bridge -> outbound`, а не в роутере.

## Прозрачный режим

Прозрачный режим включайте только после успешного `check.sh` и теста SOCKS.

Включить TCP redirect для LAN:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- enable
```

Проверить правила:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- status
```

Ожидаемый минимум:

```text
-A PREROUTING -i br0 -p tcp -j KEENETIC_XRAY
-A KEENETIC_XRAY -p tcp -j REDIRECT --to-ports 12345
```

После включения проверь с клиентского устройства:

```text
https://ifconfig.me
https://youtube.com
https://web.telegram.org
https://instagram.com
```
https://ifconfig.me Должен показать ip адрес вышего bridge

Если браузер показывает `ERR_CONNECTION_REFUSED`, значит `transparent-in` в Xray слушает не `0.0.0.0:12345`. Выполните:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/fix-transparent-listen.sh | sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- enable
```

## QUIC для YouTube

После включения transparent заблокируй UDP/443, чтобы YouTube/Chrome не пытались использовать QUIC мимо TCP-перехвата:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- block-quic
```

Отключить QUIC-блок:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- unblock-quic
```

## Автозапуск маршрутов

Xray запускается через `/opt/etc/init.d/S24xray`, но firewall-правила могут пропасть после перезагрузки роутера. После того как профиль проверен и работает, установите автозапуск transparent + QUIC-block:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/autostart-transparent.sh | sh
```

Будет создан:

```sh
/opt/etc/init.d/S25xray-transparent
```

Проверить после перезагрузки:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- status
```

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
- есть ли Xray в `/opt/sbin/xray`, `/opt/bin/xray` или другом стандартном пути;
- валиден ли `/opt/etc/xray/config.json`;
- есть ли init-скрипт `/opt/etc/init.d/S24xray`;
- запущен ли процесс Xray;
- работает ли локальный SOCKS `127.0.0.1:10808`;
- CPU/RAM.

Если Xray отсутствует, `repair.sh` попробует скачать подходящую версию под архитектуру роутера.

## Быстрый откат

Если после включения transparent пропал интернет:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- unblock-quic
```

Остановить Xray:

```sh
/opt/etc/init.d/S24xray stop
```

Вернуть backup вручную можно из:

```sh
/opt/root/xray-backups/
```

## Частые проблемы

### `sh: install: not found`

Причина: на некоторых Entware-системах нет команды `install`.

Решение: используй актуальный `main/install.sh`. В нём установка Xray делается через `cp` и `chmod`.

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/install.sh | sh -s -- "$VLESS"
```

### `failed to open file: geoip.dat`

Пример ошибки:

```text
failed to load GeoIP: private
failed to open file: geoip.dat
```

Причина: Xray ищет `geoip.dat` рядом со своим бинарником, а файла там нет.

Решение: используй актуальный `main/install.sh`. Он не использует `geoip:private`, а прописывает приватные сети напрямую.

### `ERR_CONNECTION_REFUSED` после включения transparent

Причина: `transparent-in` слушает `127.0.0.1:12345`, а для LAN-перехвата нужен `0.0.0.0:12345`.

Решение:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/fix-transparent-listen.sh | sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- enable
```

### `check.sh` показывает Xray, но нет `10808`

Признаки:

```text
xray run
слушает случайный порт, например 61219
127.0.0.1:10808 отсутствует
/opt/etc/xray/config.json отсутствует
```

Причина: запущен старый или чужой Xray-процесс, а не управляемый конфиг из этих скриптов.

Решение:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
VLESS='vless://CLIENT_LINK'
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/install.sh | sh -s -- "$VLESS"
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
```

### `Connectivity` не возвращает IP

Причины:

- неверная VLESS-ссылка;
- ссылка была вставлена с переносом строки внутри `pbk`, `sid` или UUID;
- сервер/порт недоступен;
- Reality `pbk`, `sid`, `sni`, `fp` не совпадают с сервером.

Проверка:

```sh
echo "$VLESS"
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
```

Если ссылка визуально переносится в терминале из-за ширины окна, это не страшно. Плохо, если перенос реально попал внутрь переменной.

### YouTube работает, но медленно

Сначала включи QUIC-блок:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- block-quic
```

Потом сравни скорость:

```sh
curl -L -o /dev/null https://speed.cloudflare.com/__down?bytes=10000000
curl -L --socks5-hostname 127.0.0.1:10808 -o /dev/null https://speed.cloudflare.com/__down?bytes=50000000
```

Если CPU низкий, но скорость через SOCKS в 2 раза ниже прямой, ограничение в профиле или маршруте до сервера, а не в Keenetic.

### Высокий CPU на роутере

Проверка во время YouTube:

```sh
top -bn1 | head -n 20
```

Если CPU около 80-100%, слабый роутер не вытягивает текущий профиль. Для MIPS-моделей вроде Viva лучше пробовать TCP/REALITY или менять роутер на Hopper/Giga/Hero.

### После перезагрузки снова не работает

Причина: Xray может стартовать, а firewall-правила transparent не восстановились.

Решение после того, как профиль проверен:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/autostart-transparent.sh | sh
```

Проверка после reboot:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- status
```

### Нужно срочно вернуть интернет клиенту

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- unblock-quic
```

Если нужно полностью остановить Xray:

```sh
/opt/etc/init.d/S24xray stop
```

## Удаление

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/uninstall.sh | sh
```

Скрипт остановит Xray и уберет временные firewall-цепочки, если они создавались.

Файлы Xray остаются на роутере для ручного восстановления:

```sh
/opt/bin/xray
/opt/sbin/xray
/opt/etc/xray/config.json
/opt/etc/init.d/S24xray
/opt/etc/init.d/S25xray-transparent
```

## Какой профиль создавать в 3x-ui

Для Keenetic делайте отдельного клиента в 3x-ui и тестируйте минимум два профиля.

Профиль 1: TCP/REALITY, обычно легче для слабых роутеров:

```text
Protocol: VLESS
Transport: TCP RAW
Security: REALITY
Flow: xtls-rprx-vision
Fingerprint: qq или chrome
SNI: www.microsoft.com
Target: www.microsoft.com:443
```

Профиль 2: XHTTP/REALITY, может быть устойчивее на некоторых сетях, но не всегда быстрее:

```text
Protocol: VLESS
Transport: XHTTP
Security: REALITY
Flow: пусто
Fingerprint: qq
SNI: www.microsoft.com
Path: /
Mode: auto
```

Для каждого профиля делайте одинаковый тест:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/transparent.sh | sh -s -- disable
VLESS='vless://CLIENT_LINK'
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/install.sh | sh -s -- "$VLESS"
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
curl -L --socks5-hostname 127.0.0.1:10808 -o /dev/null https://speed.cloudflare.com/__down?bytes=50000000
```

Оставляйте профиль, который дает лучшую скорость и стабильнее открывает YouTube.

Для старых MIPS-моделей вроде Keenetic Viva не жди высокой скорости на 1080p. Если через SOCKS получается около `1.8 MB/s`, это примерно `14-15 Мбит/с`: 720p обычно нормально, 1080p может буферить.
