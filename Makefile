
BASEDIR=$(PWD)
CURRENT_VERSION=`sed -ne 's/ *"version": "\(.*\)",/\1/p' package.json`
DOCKER_IMAGE_NAME=hubot-groovenauts
HUBOT_ENV ?= staging
HTTP_PORT ?= 8080
TZ ?= JST-9

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
	- docker rm redis
	docker run -d -p 6379:6379 -v $(BASEDIR)/brain:/data --name=redis redis redis-server --appendonly yes --auto-aof-rewrite-min-size 32mb --auto-aof-rewrite-percentage 50

stop-redis:
	- docker stop redis

run-hubot: run-hubot-latest
stop-hubot: stop-hubot-latest

run-hubot-latest:
	- docker rm hubot-groovenauts
	docker run -d \
	  -e HUBOT_SLACK_TEAM=$(HUBOT_SLACK_TEAM) \
	  -e HUBOT_SLACK_BOTNAME=$(HUBOT_SLACK_BOTNAME) \
	  -e HUBOT_SLACK_TOKEN=$(HUBOT_SLACK_TOKEN) \
	  -e REDIS_URL=$(REDIS_URL) \
	  -e HUBOT_AUTH_ADMIN=$(HUBOT_AUTH_ADMIN) \
	  -e HUBOT_GITHUB_TOKEN=$(HUBOT_GITHUB_TOKEN) \
	  -e HUBOT_DEPLOY_APPS_JSON=$(HUBOT_DEPLOY_APPS_JSON) \
	  -e TZ=$(TZ) \
	  -p $(HTTP_PORT):8080 \
	  --name="hubot-groovenauts" \
	  $(DOCKER_IMAGE_NAME):latest

stop-hubot-latest:
	- docker stop hubot-groovenauts

run-hubot-head:
	- docker rm hubot-groovenauts-$(HUBOT_ENV)
	docker run -d \
	  -e HUBOT_SLACK_TEAM=$(HUBOT_SLACK_TEAM) \
	  -e HUBOT_SLACK_BOTNAME=$(HUBOT_SLACK_BOTNAME) \
	  -e HUBOT_SLACK_TOKEN=$(HUBOT_SLACK_TOKEN) \
	  -e REDIS_URL=$(REDIS_URL) \
	  -e HUBOT_AUTH_ADMIN=$(HUBOT_AUTH_ADMIN) \
	  -e HUBOT_GITHUB_TOKEN=$(HUBOT_GITHUB_TOKEN) \
	  -e HUBOT_DEPLOY_APPS_JSON=$(HUBOT_DEPLOY_APPS_JSON) \
	  -e TZ=$(TZ) \
	  -p $(HTTP_PORT):8080 \
	  --name="hubot-groovenauts-$(HUBOT_ENV)" \
	  $(DOCKER_IMAGE_NAME):$(CURRENT_VERSION)

stop-hubot-head:
	- docker stop hubot-groovenauts-$(HUBOT_ENV)

run-test: build-latest
	- docker rm hubot-groovenauts-test
	docker run -it -e REDIS_URL=$(REDIS_URL) -e TZ=$(TZ) --name=hubot-groovenauts-test $(DOCKER_IMAGE_NAME):latest node_modules/mocha/bin/mocha
