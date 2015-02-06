# Description
#   朝会の時間を通知
#

cron = require("cron").CronJob

module.exports = (robot) ->
  new cron "0 10 10 * * 1-5", () =>
    robot.send {room: "general"}, "<@channel> そろそろ朝会の時間ですよ"
  , null, true, "Asia/Tokyo"
