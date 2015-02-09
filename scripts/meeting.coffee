# Description
#   朝会の時間を通知
#

cron = require("cron").CronJob
holiday = require "holiday-jp"

module.exports = (robot) ->
  new cron "0 10 10 * * 1-5", () ->
    if !(holiday.isHoliday(new Date()))
      robot.send {room: "general"}, "<!channel> そろそろ朝会の時間ですよ"
  , null, true, "Asia/Tokyo"
