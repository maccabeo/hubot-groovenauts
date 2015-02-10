# Description
#   朝会の時間を通知
#

cron = require("cron").CronJob
holiday = require "holiday-jp"

module.exports = (robot) ->
  new cron "0 10 10 * * 1-5", () ->
    if !(holiday.isHoliday(new Date()))
      robot.send {room: "general"}, "<!channel> そろそろ朝会の時間ですよ"
    else
      date = new Date()
      d = holiday.between(date, date)[0]
      robot.send {room: "general"}, "今日は #{d.name} でおやすみです"
  , null, true, "Asia/Tokyo"
