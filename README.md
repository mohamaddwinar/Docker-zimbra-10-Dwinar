# Docker Zimbra 10 Dwinar

Docker-based Zimbra 10.1 Network Edition lab installer for Rocky Linux 9.

This repository provides a Docker build and runtime installer for deploying a single-node Zimbra 10.1 server in a container. The current supported Docker target is **Rocky Linux 9**.

> This project is intended for lab, testing, development, and automation validation. For production deployment, use a VM or bare-metal installation and follow Zimbra's official system, DNS, TLS, backup, security, and licensing requirements.

---

## Current Status

| Component | Status |
|---|---|
| Rocky Linux 9 Docker build | Working |
| Zimbra 10.1 installer phase 1 | Working |
| Zimbra setup phase 2 | Working |
| Local BIND DNS inside container | Working |
| OnlyOffice service | Working |
| Background container run | Working |
| Ubuntu Docker variants | Not yet implemented |

Tested release:

```text
Release 10.1.19.GA.4688.RHEL9_64.20240911074203 NETWORK edition.
```

---

## Repository Structure

```text
.
├── .dockerignore
├── .gitattributes
├── .gitignore
├── CHANGELOG.md
├── LICENSE
├── README.md
├── SECURITY.md
├── env.example
└── docker-zimbra-rocky9/
    ├── README-Rocky9.md
    └── docker/
        ├── Dockerfile
        ├── Makefile
        ├── docker-compose.yml
        └── opt/
            └── start.sh
```

---

## Requirements

Host requirements:

- Linux host with Docker Engine
- Internet access from the host and container
- Minimum 8 GB RAM recommended
- Minimum 20 GB free disk space recommended
- `linux/amd64` host recommended
- Required ports must be free on the Docker host

Required exposed ports:

| Port | Service |
|---:|---|
| 25 | SMTP |
| 80 | HTTP / Webmail proxy |
| 443 | HTTPS / Webmail proxy |
| 465 | SMTPS |
| 587 | Submission |
| 110 | POP3 |
| 143 | IMAP |
| 993 | IMAPS |
| 995 | POP3S |
| 7071 | Zimbra Admin Console |
| 9071 | Admin proxy / service |

---

## Build Image

Clone the repository:

```bash
git clone https://github.com/mohamaddwinar/Docker-zimbra-10-Dwinar.git
cd Docker-zimbra-10-Dwinar/docker-zimbra-rocky9/docker
```

Build the Docker image:

```bash
docker build --rm -t docker-zimbra-10_1-rocky9-dwinar:latest .
```

Check the image:

```bash
docker images | grep docker-zimbra
```

Expected image name:

```text
docker-zimbra-10_1-rocky9-dwinar:latest
```

---

## Run Container

Run in background mode:

```bash
docker rm -f zimbra-rocky9 2>/dev/null || true

docker run -d --name zimbra-rocky9 \
  --hostname zimbra10.dwinar.web.id \
  --dns 8.8.8.8 --dns 1.1.1.1 \
  --privileged \
  -e PASSWORD='ChangeMe123!' \
  -e TIMEZONE='Asia/Jakarta' \
  -e DNS_FORWARDER_1='8.8.8.8' \
  -e DNS_FORWARDER_2='1.1.1.1' \
  -p 25:25 -p 80:80 -p 443:443 -p 465:465 -p 587:587 \
  -p 110:110 -p 143:143 -p 993:993 -p 995:995 \
  -p 7071:7071 -p 9071:9071 \
  docker-zimbra-10_1-rocky9-dwinar:latest
```

Monitor installation logs:

```bash
docker logs -f zimbra-rocky9
```

The first run downloads the Zimbra installer, installs packages, configures Zimbra, and starts all services. This can take several minutes depending on network and host performance.

---

## Docker Compose

From the Docker directory:

```bash
cd docker-zimbra-rocky9/docker

docker compose up -d --build
docker logs -f zimbra-rocky9
```

Stop compose deployment:

```bash
docker compose down
```

Remove the persistent volume as well:

```bash
docker compose down -v
```

---

## Makefile Helpers

From `docker-zimbra-rocky9/docker`:

```bash
make build
make run
make logs
make shell
make status
make stop
make rm
```

Docker Compose helpers:

```bash
make compose-up
make compose-down
```

---

## Access Zimbra

Admin Console:

```text
https://SERVER-IP:7071
```

Default admin account depends on the container hostname.

Example:

```text
Hostname : zimbra10.dwinar.web.id
Domain   : dwinar.web.id
Admin    : admin@dwinar.web.id
Password : ChangeMe123!
```

Change `PASSWORD` during `docker run` for a custom admin password.

---

## Verify Installation

Enter the container:

```bash
docker exec -it zimbra-rocky9 bash
```

Check Zimbra status:

```bash
su - zimbra
zmcontrol status
zmcontrol -v
```

Expected services include:

```text
ldap                    Running
logger                  Running
mailbox                 Running
mta                     Running
proxy                   Running
onlyoffice              Running
zimbra webapp           Running
zimbraAdmin webapp      Running
zmconfigd               Running
```

---

## Runtime Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PASSWORD` | `ChangeMe123!` | Admin account password |
| `TIMEZONE` | `Asia/Jakarta` | Zimbra timezone |
| `DNS_FORWARDER_1` | `8.8.8.8` | First DNS forwarder for local BIND |
| `DNS_FORWARDER_2` | `1.1.1.1` | Second DNS forwarder for local BIND |
| `ZIMBRA_INSTALLER_URL` | Zimbra 10.1 Rocky 9 installer URL | Custom installer URL |

The domain is derived automatically from the container hostname.

Example:

```text
zimbra10.dwinar.web.id -> domain dwinar.web.id
```

---

## Useful Commands

View running containers:

```bash
docker ps
```

View all containers:

```bash
docker ps -a
```

Follow logs:

```bash
docker logs -f zimbra-rocky9
```

Open shell:

```bash
docker exec -it zimbra-rocky9 bash
```

Restart Zimbra from inside the container:

```bash
su - zimbra -c "zmcontrol restart"
```

Start existing stopped container:

```bash
docker start zimbra-rocky9
```

Remove container:

```bash
docker rm -f zimbra-rocky9
```

---

## Foreground Run Note

If the container is started with `-it`, pressing `Ctrl+C` can stop the container.

Detach safely without stopping the container:

```text
Ctrl + P, then Ctrl + Q
```

Recommended mode is `-d` background mode.

---

## Publish to Docker Hub

Build locally first:

```bash
cd docker-zimbra-rocky9/docker

docker build --rm -t docker-zimbra-10_1-rocky9-dwinar:latest .
```

Login to Docker Hub:

```bash
docker login -u mohamaddwinar
```

Tag the image:

```bash
docker tag docker-zimbra-10_1-rocky9-dwinar:latest mohamaddwinar/docker-zimbra-10-dwinar:rocky9
docker tag docker-zimbra-10_1-rocky9-dwinar:latest mohamaddwinar/docker-zimbra-10-dwinar:10.1-rocky9
docker tag docker-zimbra-10_1-rocky9-dwinar:latest mohamaddwinar/docker-zimbra-10-dwinar:10.1.19-rocky9
docker tag docker-zimbra-10_1-rocky9-dwinar:latest mohamaddwinar/docker-zimbra-10-dwinar:latest
```

Push the image:

```bash
docker push mohamaddwinar/docker-zimbra-10-dwinar:rocky9
docker push mohamaddwinar/docker-zimbra-10-dwinar:10.1-rocky9
docker push mohamaddwinar/docker-zimbra-10-dwinar:10.1.19-rocky9
docker push mohamaddwinar/docker-zimbra-10-dwinar:latest
```

Or use Makefile:

```bash
make tag-dockerhub
make push-dockerhub
```

Recommended Docker Hub description:

```text
Docker image for Zimbra 10.1 Network Edition on Rocky Linux 9 for lab and testing.
```

Recommended Docker Hub tags:

```text
zimbra, zimbra-10, rocky-linux, docker, mail-server, email-server, devops, testing
```

---

## Persistent Data

The Dockerfile declares:

```text
/opt/zimbra
```

The Docker Compose file maps this to a named volume:

```text
zimbra_data:/opt/zimbra
```

For a clean reinstall, remove the container and the volume:

```bash
docker rm -f zimbra-rocky9

docker volume rm docker_zimbra_data 2>/dev/null || true
```

Volume name may differ depending on the compose project name. Check with:

```bash
docker volume ls | grep zimbra
```

---

## Troubleshooting

Check real installer logs:

```bash
docker exec -it zimbra-rocky9 bash
ls -lah /tmp/install.log.* /opt/zimbra-install/*.log 2>/dev/null
```

Follow installer log:

```bash
docker exec -it zimbra-rocky9 bash -lc 'tail -f /opt/zimbra-install/install.log'
```

Follow DNF log:

```bash
docker exec -it zimbra-rocky9 bash -lc 'tail -f /var/log/dnf.log'
```

Check running installer process:

```bash
docker exec -it zimbra-rocky9 bash -lc "ps -ef | egrep 'install.sh|zmsetup|dnf|rpm|zimbra' | grep -v grep"
```

Check DNS inside container:

```bash
docker exec -it zimbra-rocky9 bash -lc 'hostname -f; hostname -I; cat /etc/hosts; cat /etc/resolv.conf; getent hosts repo.zimbra.com; getent hosts files.zimbra.com'
```

---

## Roadmap

Planned Docker variants:

- Ubuntu 18.04
- Ubuntu 20.04
- Ubuntu 22.04
- Ubuntu 24.04

The automation logic is based on the tested Ansible role:

```text
https://github.com/mohamaddwinar/ansible-zimbra-10-Dwinar
```

---

## License

This repository's scripts, Dockerfile, and documentation are released under the MIT License.

Zimbra packages, binaries, trademarks, and licensing are owned by their respective owners. This repository does not redistribute a Zimbra license and does not replace official Zimbra licensing requirements.
