FROM node:0.10-onbuild

MAINTAINER nagachika@ruby-lang.org

EXPORT 8080

CMD ["bin/hubot", "--adapter", "slack"]
