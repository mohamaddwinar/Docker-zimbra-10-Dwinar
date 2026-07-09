IMAGE ?= docker-zimbra-10_1-rocky9-dwinar
TAG ?= latest

.PHONY: all build run shell clean

all: build

build:
	docker build --rm -t $(IMAGE):$(TAG) .

run:
	docker run --name zimbra-rocky9 \
	  --hostname zimbra10.dwinar.web.id \
	  --dns 127.0.0.1 --dns 8.8.8.8 \
	  --privileged \
	  -e PASSWORD='ChangeMe123!' \
	  -e TIMEZONE='Asia/Jakarta' \
	  -p 25:25 -p 80:80 -p 443:443 -p 465:465 -p 587:587 \
	  -p 110:110 -p 143:143 -p 993:993 -p 995:995 \
	  -p 7071:7071 -p 9071:9071 \
	  -it $(IMAGE):$(TAG)

shell:
	docker exec -it zimbra-rocky9 bash

clean:
	docker rm -f zimbra-rocky9 || true
