#! /bin/sh

## generate apps.json for hubot-deploy (https://github.com/atmos/hubot-deploy)
if [ -n "${HUBOT_DEPLOY_APPS_JSON_BASE64}" ]; then
  echo "${HUBOT_DEPLOY_APPS_JSON_BASE64}" | base64 -d > apps.json
fi

exec "$@"
