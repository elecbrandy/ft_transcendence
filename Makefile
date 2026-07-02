FILE_PATH=./srcs/docker-compose.yml
ENV_FILE=./srcs/.env

.PHONY: all
all:
	@make up

.PHONY: up
up:
	docker compose --env-file $(ENV_FILE) -f $(FILE_PATH) up --build -d

.PHONY: down
down:
	docker compose --env-file $(ENV_FILE) -f $(FILE_PATH) down

.PHONY: clean
clean: down
	docker volume prune -f
	docker system prune -a -f
