IMAGE=docker-zimbra-10-rocky9-dwinar:latest
CONTAINER=zimbra-rocky9

build:
	docker build --rm -t $(IMAGE) .

up:
	docker compose up -d --build

logs:
	docker logs -f $(CONTAINER)

shell:
	docker exec -it $(CONTAINER) bash

status:
	docker exec -it $(CONTAINER) su - zimbra -c "zmcontrol status"

version:
	docker exec -it $(CONTAINER) su - zimbra -c "zmcontrol -v"

down:
	docker compose down
