FROM node:0.10-onbuild

MAINTAINER nagachika@ruby-lang.org

CMD ["bin/hubot", "--adapter", "slack"]
