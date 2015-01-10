# Description:
#   GitHub の WebHook からの通知を受ける
#
# Dependencies:
#   "url": ""
#   "querystring": ""
#
# Configuration:
#   GitHub で以下の設定が必要です
#
#   1. API token 取得: curl -u 'username' -d '{"scopes":["repo"],"note":"hubot"}' \
#                         https://api.github.com/authorizations
#   2. GitHub リポジトリの WebHook 設定に次の URL を設定:
#         http://<HUBOT_URL>:<PORT>/hubot/gh-notify
#
# Commands:
#   hubot github notify <repo> to <room> -- <repo> のイベントを <room> に通知する
#   hubot github notify show -- GitHub イベントのリポジトリ毎の通知先 room を表示
#
# URLS:
#   POST /hubot/gh-notify
#
# Authors:
#   nagachika


url = require('url')
querystring = require('querystring')

module.exports = (robot) ->
  robot.respond /github\s+notify\s+([a-z0-9_./-]+)\s+to\s+([^\s]+)\s*$/, (msg) ->
    unique = (array) ->
      output = {}
      output[array[key]] = array[key] for key in [0...array.length]
      value for key, value of output
    repo = msg.match[1]
    room = msg.match[2]
    m = (robot.brain.get("gh-notify-repository-to-rooms") || {})
    r = (m[repo] || [])
    r.push(room)
    m[repo] = unique r
    robot.brain.set("gh-notify-repository-to-rooms", m)
    msg.reply "#{repo} の Pull Request の通知を #{room} に送信します"

  robot.respond /github\s+notify\s+show\s*$/, (msg) ->
    msg.send "GitHub の Pull Request の通知設定一覧"
    repos = (robot.brain.get("gh-notify-repository-to-rooms") || {})
    for repo, rooms of repos
      rooms ||= []
      msg.send "#{repo} → #{rooms.join(", ")}"

  robot.router.post "/hubot/gh-notify", (req, res) ->
    data = req.body
    repo = data.repository.full_name

    for room in repo2rooms(robot, repo)
      try
        switch req.header("X-Github-Event")
          when "pull_request"
            announcePullRequest robot, data, (what) ->
              robot.messageRoom room, what
          #when "pull_request_review_comment"
          #  announcePullRequestReviewComment robot, data, (what) ->
          #    robot.messageRoom room, what
      catch error
        robot.messageRoom room, "GitHub 通知処理中にエラーが発生しました: #{error}"
        console.log "github pull request notifier error: #{error}. Request: #{req.body}"

    res.end ""

repo2rooms = (robot, repo) ->
  m = (robot.brain.get("gh-notify-repository-to-rooms") || {})
  return (m[repo] || [])

announcePullRequest = (robot, data, cb) ->
  switch data.action
    when 'opened'
      mentioned = data.pull_request.body?.match(/(^|\s)(@[\w\-\/]+)/g)

      if mentioned
        unique = (array) ->
          output = {}
          output[array[key]] = array[key] for key in [0...array.length]
          value for key, value of output

        mentioned = mentioned.filter (nick) ->
          slashes = nick.match(/\//g)
          slashes is null or slashes.length < 2

        mentioned = mentioned.map (nick) -> nick.trim()
        mentioned = unique mentioned
        mentioned = mentioned.map (nick) ->
          for _uid, user of robot.brain.users()
            if "@#{user.githubLogin}" == nick
              nick = "@#{user.name}"
              break
          "<#{nick}>"

        mentioned_line = "\nMentioned: #{mentioned.join(", ")}"
      else
        mentioned_line = ''

      cb "PR が作成されました \"#{data.pull_request.title}\" by #{data.pull_request.user.login}: #{data.pull_request.html_url}#{mentioned_line}"

    when "synchronized"
      cb "PR にコミットが追加pushされました \"#{data.pull_request.title}\": #{data.pull_requst.html_url}"

    when "closed"
      cb "PR が close されました \"#{data.pull_request.title}\" by #{data.pull_request.merged_by?.login}: #{data.pull_requst.html_url}"
