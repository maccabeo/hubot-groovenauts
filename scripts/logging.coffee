# Description:
#  output log to all messages
# # Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#
# Author:
#   nagachika

module.exports = (robot) ->
  fluent = require("fluent-logger")
  fluent.configure("hubot.#{process.env.HUBOT_SLACK_TEAM}", { host: "172.17.42.1", port: 24224 })

  robot.hear /./, (msg) ->
    room = msg.message.room
    username = msg.message.user.name
    text = msg.message.text
    fluent.emit "chatlog", {room: room, user: username, text: text}
