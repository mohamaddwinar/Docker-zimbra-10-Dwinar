# Docker Zimbra 10.1 Rocky 9 - Dwinar

Versi awal untuk mengganti repo lama `docker-zimbra-8_8_15-dwinar` yang masih memakai Ubuntu 16.04 dan Zimbra 8.8.15.

## Build

```bash
cd docker
docker build --rm -t docker-zimbra-10_1-rocky9-dwinar:latest .
```

## Run

```bash
docker run --name zimbra-rocky9 \
  --hostname zimbra10.dwinar.web.id \
  --dns 127.0.0.1 --dns 8.8.8.8 \
  --privileged \
  -e PASSWORD='ChangeMe123!' \
  -e TIMEZONE='Asia/Jakarta' \
  -p 25:25 -p 80:80 -p 443:443 -p 465:465 -p 587:587 \
  -p 110:110 -p 143:143 -p 993:993 -p 995:995 \
  -p 7071:7071 -p 9071:9071 \
  -it docker-zimbra-10_1-rocky9-dwinar:latest
```

## Compose

```bash
cd docker
docker compose up -d --build
```

## Check

```bash
docker exec -it zimbra-rocky9 bash
su - zimbra
zmcontrol status
zmcontrol -v
```

## Notes

- Image ini install Zimbra saat container pertama kali start.
- `/opt/zimbra` dijadikan Docker volume agar data tetap persist.
- Untuk testing/dev, pakai VM khusus dan snapshot.
- Untuk production, lebih aman tetap VM bare OS seperti role Ansible yang sudah sukses.
