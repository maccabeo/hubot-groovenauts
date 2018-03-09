FROM node:0.10-onbuild

MAINTAINER mattia.moretti@trithemius.at

EXPOSE 8080

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bin/hubot", "--adapter", "slack"]
