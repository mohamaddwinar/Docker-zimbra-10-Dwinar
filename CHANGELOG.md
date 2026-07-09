# Changelog

## 1.0.0 - 2026-07-09

Initial Rocky Linux 9 Docker baseline.

### Added

- Dockerfile for Rocky Linux 9.
- Runtime `start.sh` installer for Zimbra 10.1 Network Edition.
- Local BIND DNS configuration inside container.
- Zimbra phase 1 and phase 2 automation.
- Retry and diagnostic logging for Zimbra repository downloads.
- Docker Compose example.
- Makefile helper commands.
- README, Rocky 9 notes, license, `.gitignore`, `.dockerignore`, and `.gitattributes`.

### Tested

- Zimbra release: `10.1.19.GA.4688.RHEL9_64.20240911074203 NETWORK edition`.
- Services running: LDAP, logger, mailbox, MTA, proxy, OnlyOffice, webapps, and zmconfigd.
