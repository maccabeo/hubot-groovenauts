# Description:
#  output log to all messages
# # Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot log search <words> -- このチャンネルの発言ログを検索
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

  # use docker host mongodb
  mongo = require("mongodb").MongoClient
  robot.respond /log search (.+)/, (msg) ->
    mongo.connect "mongodb://172.17.42.1:27017/hubot_#{process.env.HUBOT_SLACK_TEAM}", (err, db) ->
      if (err)
        msg.send "mongodb connection failure: #{err}"
      else
        collection = db.collection("chat_logs")
        collection.find({room: msg.message.room, text: new RegExp(msg.match[1])}).toArray (err, items) ->
          if (err)
            msg.send "mongodb query failure: #{err}"
          else
            buf = "#{items.length} matches:\n"
            for m in items
              buf += "#{m["user"]}: #{m["text"]}\n"
            msg.send buf
          db.close
