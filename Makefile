
export DOCKER_IMAGE_NAME=hubot-groovenauts
export HUBOT_ENV ?= staging
export HTTP_PORT ?= 8080
export TZ ?= JST-9

include $(HUBOT_ENV).mk

all: run-hubot
run: run-hubot
run-all: run-redis run-hubot
stop: stop-hubot
stop-all: stop-hubot stop-redis

build:
	docker build -t $(DOCKER_IMAGE_NAME):latest .

reload: build stop-hubot run-hubot

run-redis:
	- docker-compose rm redis
	docker-compose up -d redis

stop-redis:
	- docker-compose stop redis

run-hubot:
	- docker-compose rm hubot
	docker-compose up -d hubot

stop-hubot:
	- docker-compose stop hubot

run-test: build
	- docker-compose -f docker-compose.test.yml rm hubot-test
	docker-compose -f docker-compose.test.yml run hubot-test node_modules/mocha/bin/mocha

