# Description:
#  output log to all messages
# # Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot log search <regexp> -- このチャンネルの発言ログを検索
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


  format_datetime = (date) ->
    month = date.getMonth()
    day = date.getDate()
    hour = date.getHours()
    min = date.getMinutes()
    sec = date.getSeconds()
    if month < 10
      month = "0" + month
    if day < 10
      day = "0" + day
    if hour < 10
      hour = "0" + hour
    if min < 10
      min = "0" + min
    if sec < 10
      sec = "0" + sec
    return "#{date.getFullYear()}-#{month}-#{day} #{hour}:#{min}:#{sec}"


  # use docker host mongodb
  mongo = require("mongodb").MongoClient

  mongo_query = (msg, query, cb) ->
    mongo.connect "mongodb://172.17.42.1:27017/hubot_#{process.env.HUBOT_SLACK_TEAM}", (err, db) ->
      if (err)
        msg.send "mongodb connection failure: #{err}"
      else
        collection = db.collection("chat_logs")
        collection.find(query).toArray (err, items) ->
          if (err)
            msg.send "mongodb query failure: #{err}"
          else
            cb(msg, items)
          db.close

  robot.respond /log\s+search\s+(.+)/, (msg) ->
    mongo_query msg, {room: msg.message.room, text: new RegExp(msg.match[1])}, (_msg, items) ->
      buf = "#{items.length} matches:\n"
      for m in items
        date = m["time"]
        date_str = format_datetime(date)
        buf += "#{m["user"]}:#{date_str}: #{m["text"]}\n"
      _msg.send buf
