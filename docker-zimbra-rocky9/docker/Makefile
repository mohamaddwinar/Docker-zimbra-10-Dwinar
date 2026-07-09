IMAGE ?= docker-zimbra-10_1-rocky9-dwinar
TAG ?= latest
CONTAINER ?= zimbra-rocky9
DOCKERHUB_REPO ?= mohamaddwinar/docker-zimbra-10-dwinar

.PHONY: build run logs shell status stop rm compose-up compose-down tag-dockerhub push-dockerhub

build:
	docker build --rm -t $(IMAGE):$(TAG) .

run:
	docker rm -f $(CONTAINER) 2>/dev/null || true
	docker run -d --name $(CONTAINER) \
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
	  $(IMAGE):$(TAG)

logs:
	docker logs -f $(CONTAINER)

shell:
	docker exec -it $(CONTAINER) bash

status:
	docker exec -it $(CONTAINER) bash -lc 'su - zimbra -c "zmcontrol status && zmcontrol -v"'

stop:
	docker stop $(CONTAINER)

rm:
	docker rm -f $(CONTAINER) 2>/dev/null || true

compose-up:
	docker compose up -d --build

compose-down:
	docker compose down

tag-dockerhub:
	docker tag $(IMAGE):$(TAG) $(DOCKERHUB_REPO):rocky9
	docker tag $(IMAGE):$(TAG) $(DOCKERHUB_REPO):10.1-rocky9
	docker tag $(IMAGE):$(TAG) $(DOCKERHUB_REPO):10.1.19-rocky9
	docker tag $(IMAGE):$(TAG) $(DOCKERHUB_REPO):latest

push-dockerhub: tag-dockerhub
	docker push $(DOCKERHUB_REPO):rocky9
	docker push $(DOCKERHUB_REPO):10.1-rocky9
	docker push $(DOCKERHUB_REPO):10.1.19-rocky9
	docker push $(DOCKERHUB_REPO):latest
