# Description:
#   times_xxx のつぶやきを #timeline に流す
#
# Commands:
#   hubot timelines webhook URL -- WEBHOOK URL を URL に設定します
#   hubot timelines icon USER EMOJI -- USER のアイコンを EMOJI に設定します
#
# Authors:
#   nagachika

Slack = require("slack-node");

module.exports = (robot) ->
  robot.respond /timelines\s+webhook\s+([^\s]+)\s*$/, (msg) ->
    url = msg.match[1]
    robot.brain.set("timelines-webhook-url", url)
    msg.reply "timelines の WebHook URL を #{url} に設定しました"

  robot.respond /timelines\s+icon\s+([a-zA-Z0-9_-]+)\s+:?([a-zA-Z0-9_-]+):?\s*$/, (msg) ->
    username = msg.match[1]
    icon_emoji = ":#{msg.match[2]}:"
    icons = (robot.brain.get("timelines-icons") || {})
    icons[username] = icon_emoji
    robot.brain.set("timelines-icons", icons)
    msg.reply "timelines の #{username} のアイコンを #{icon_emoji} に設定しました"

  robot.hear /./, (msg) ->
    if msg.message.room.match(/^times_/)
      url = robot.brain.get("timelines-webhook-url")
      if url
        slack = new Slack()
        slack.setWebhook(url)
        icons = (robot.brain.get("timelines-icons") || {})
        icon_emoji = (icons[msg.message.user.name] || ":ghost:")
        slack.webhook {
          channel: "#timeline",
          username: "#{msg.message.user.name}(at #{msg.message.room})",
          icon_emoji: icon_emoji,
          text: msg.message.text
        }, (err, response) ->
          if err
            robot.logger.error("timelines webhook error: #{err}")
