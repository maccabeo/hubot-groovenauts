
BASEDIR=$(PWD)
REDIS_URL=redis://`boot2docker ip`:6379

include env.mk

all: run-hubot
run-all: run-redis run-hubot
stop: stop-hubot
stop-all: stop-hubot stop-redis

reload: stop-hubot run-hubot

run-redis:
	- docker rm redis
	docker run -d -p 6379:6379 -v $(BASEDIR)/brain:/data --name=redis redis redis-server --appendonly yes

stop-redis:
	docker stop redis

run-hubot:
	- docker rm hubot-naga
	docker run -d \
	  -e HUBOT_SLACK_TEAM=$(HUBOT_SLACK_TEAM) \
	  -e HUBOT_SLACK_BOTNAME=$(HUBOT_SLACK_BOTNAME) \
	  -e HUBOT_SLACK_TOKEN=$(HUBOT_SLACK_TOKEN) \
	  -e REDIS_URL=$(REDIS_URL) \
	  -e HUBOT_AUTH_ADMIN=$(HUBOT_AUTH_ADMIN) \
	  --name="hubot-naga" \
	  hubot-naga

stop-hubot:
	docker stop hubot-naga

