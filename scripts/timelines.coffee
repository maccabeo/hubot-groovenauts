# Description:
#   times_xxx のつぶやきを #timeline に流す
#
# Commands:
#
# Authors:
#   nagachika


module.exports = (robot) ->
  robot.hear /./, (msg) ->
    if msg.message.room.match(/^times_/)
      msg.envelope.room = "#timeline"
      msg.send "#{msg.message.user.name} at ##{msg.message.room} : #{msg.message.text}"
