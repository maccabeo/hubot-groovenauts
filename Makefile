
export CURRENT_VERSION=`sed -ne 's/ *"version": "\(.*\)",/\1/p' package.json`
export DOCKER_IMAGE_NAME=hubot-groovenauts
export HUBOT_ENV ?= staging
export HTTP_PORT ?= 8080
export TZ ?= JST-9

include $(HUBOT_ENV).mk

# for Boot2docker users' convinience
ifndef REDIS_URL
REDIS_URL=redis://`boot2docker ip`:6379/$(HUBOT_ENV)
endif

all: run-hubot
run: run-hubot
run-all: run-redis run-hubot
stop: stop-hubot
stop-all: stop-hubot stop-redis

build-latest:
	docker build -t $(DOCKER_IMAGE_NAME):latest .

build-head:
	docker build -t $(DOCKER_IMAGE_NAME):$(CURRENT_VERSION) .

reload: build-latest stop-hubot run-hubot

run-redis:
	- docker-compose rm redis
	docker-compose up -d redis

stop-redis:
	- docker-compose stop redis

run-hubot: run-hubot-latest
stop-hubot: stop-hubot-latest

run-hubot-latest:
	- docker-compose rm hubot-latest
	docker-compose up -d hubot-latest

stop-hubot-latest:
	- docker-compose stop hubot-latest

run-hubot-head:
	- docker-compose rm hubot-head
	docker-compose up -d hubot-head

stop-hubot-head:
	- docker-compose stop hubot-head

run-test: build-latest
	- docker-compose rm hubot-test
	docker-compose run hubot-test node_modules/mocha/bin/mocha

