# Docker Zimbra 10.1 Rocky 9

Initial Docker baseline for Zimbra 10.1 Network Edition on Rocky Linux 9.

## Build

```bash
cd docker
docker build --rm -t docker-zimbra-10-rocky9-dwinar:latest .
```

## Run

```bash
docker compose up -d --build
```

## Check

```bash
docker exec -it zimbra-rocky9 bash
su - zimbra
zmcontrol status
zmcontrol -v
```
