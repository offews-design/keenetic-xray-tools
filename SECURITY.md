# Security Policy

## Sensitive Data

Do not commit production VPN data to this repository.

Never publish:

- real `vless://` links;
- client UUIDs;
- Reality private keys;
- production Reality public keys, short IDs, seeds, or subscription URLs;
- server IP addresses;
- 3x-ui panel URLs;
- exported production `config.json` files.

Use placeholders in documentation and examples:

```text
CLIENT_UUID
vpn.example.com
PUBLIC_KEY
SHORT_ID
CLIENT_LINK
```

## Before Pushing

Run a quick local scan:

```sh
grep -RniE 'vless://|sub/|privateKey|shortId|pbk=|sid=|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' .
```

Review all matches before pushing.

## Operational Safety

- Test new profiles with `check.sh` before enabling transparent routing.
- Keep backup files on the router, not in the repository.
- Use one client profile per router.
- Rotate any credential that was accidentally committed.
