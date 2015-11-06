#! /bin/sh

## generate apps.json for hubot-deploy (https://github.com/atmos/hubot-deploy)
if [ -n "${HUBOT_DEPLOY_APPS_JSON}" ]; then
  echo "${HUBOT_DEPLOY_APPS_JSON}" > apps.json
fi

exec "$@"
