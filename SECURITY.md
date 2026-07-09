# Security Policy

This project is intended for lab, testing, development, and automation validation.
Do not expose the default container directly to the internet without reviewing security, licensing, DNS, TLS, firewall, backup, and update requirements.

## Notes

- Change the default `PASSWORD` before use.
- Use a valid hostname and DNS records.
- Review exposed ports before running the container.
- Review Zimbra license terms before using Network Edition packages.
- Docker image vulnerability scanners may report findings from the base OS and application dependencies. Patch and rebuild regularly.
