# Description:
#   None
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   cam
#
# Author:
#   tbwIIU

cam1 = [ "http://trithemius.at:2180/snappy/cam1.jpg" ]
cam2 = [ "http://trithemius.at:2180/snappy/cam2.jpg" ]

module.exports = (robot) ->
  robot.hear /(^|\W)cam(\z|\W|$)/i, (msg) ->
    msg.send msg.random cam1
    msg.send msg.random cam2
