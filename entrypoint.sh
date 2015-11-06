#! /bin/sh

## generate apps.json for hubot-deploy (https://github.com/atmos/hubot-deploy)
if [ -n "${HUBOT_DEPLOY_APPS_JSON_BASE64}" ]; then
  echo "${HUBOT_DEPLOY_APPS_JSON_BASE64}" | base64 -d > apps.json
fi

## set REDIS_URL from REDIS_PORT_6379_TCP_PORT (set by `--link`)
if [ -z "${REDIS_URL}" -a -n "${REDIS_PORT_6379_TCP}" ]; then
  export REDIS_URL=redis://${REDIS_PORT_6379_TCP_ADDR}:${REDIS_PORT_6379_TCP_PORT}/
fi

exec "$@"
