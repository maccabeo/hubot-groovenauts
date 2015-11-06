FROM node:0.10-onbuild

MAINTAINER nagachika@ruby-lang.org

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bin/hubot", "--adapter", "slack"]
