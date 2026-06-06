# Keenetic Xray Tools

Standard target:

- Keenetic router with Entware/OPKG enabled
- Xray binary at `/opt/bin/xray`
- Config at `/opt/etc/xray/config.json`
- Service script at `/opt/etc/init.d/S24xray`

Traffic policy:

- Telegram / YouTube / Instagram -> proxy
- Everything else -> direct

## Install From GitHub

Replace `vless://...` with the personal Keenetic client link from 3x-ui:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/install.sh | sh -s -- 'vless://...'
```

Check:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/check.sh | sh
```

Uninstall:

```sh
curl -fsSL https://raw.githubusercontent.com/offews-design/keenetic-xray-tools/main/uninstall.sh | sh
```

## Local Install

Copy the folder to the router or download the scripts, then run:

```sh
sh keenetic-install.sh 'vless://...'
```

Optional transparent redirect mode:

```sh
sh keenetic-install.sh 'vless://...' --transparent
```

Start with non-transparent mode first. Transparent mode changes firewall rules and should be enabled only after Xray itself works.

## Check

```sh
sh keenetic-check.sh
```

## Uninstall

```sh
sh keenetic-uninstall.sh
```
