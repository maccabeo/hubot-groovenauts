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
#   hubot github notify remove <repo> to <room> -- <repo> のイベントの <room> への通知をやめる
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
    msg.reply "#{repo} の通知を #{room} に送信します"

  robot.respond /github\s+notify\s+show\s*$/, (msg) ->
    msg.send "GitHub の通知設定一覧"
    repos = (robot.brain.get("gh-notify-repository-to-rooms") || {})
    for repo, rooms of repos
      rooms ||= []
      msg.send "#{repo} → #{rooms.join(", ")}"

  robot.respond /github\s+notify\s+remove\s+([a-z0-9_./-]+)\s+to\s+([^\s]+)\s*$/, (msg) ->
    unique = (array) ->
      output = {}
      output[array[key]] = array[key] for key in [0...array.length]
      value for key, value of output
    repo = msg.match[1]
    room = msg.match[2]
    m = (robot.brain.get("gh-notify-repository-to-rooms") || {})
    r = (m[repo] || [])
    r = r.filter (rm) -> rm isnt room
    m[repo] = unique r
    robot.brain.set("gh-notify-repository-to-rooms", m)
    msg.reply "#{repo} の通知を #{room} に送信するのをやめます"

  robot.router.post "/hubot/gh-notify", (req, res) ->
    data = req.body
    repo = data.repository.full_name

    rooms = repo2rooms(robot, repo)
    try
      switch req.header("X-Github-Event")
        when "pull_request"
          announcePullRequest robot, data, (what) ->
            for room in rooms
              robot.messageRoom room, what
        when "pull_request_review_comment"
          announcePullRequestReviewComment robot, data, (what) ->
            for room in rooms
              robot.messageRoom room, what
        when "issues"
          announceIssue robot, data, (what) ->
            for room in rooms
              robot.messageRoom room, what
        when "issue_comment"
          announceIssueComment robot, data, (what) ->
            for room in rooms
              robot.messageRoom room, what
    catch error
      console.log "github pull request notifier error: #{error}. Request: #{JSON.stringify(req.body)}"
      for _uid, user of robot.brain.users()
        if robot.auth.isAdmin(user)
          robot.messageRoom user.name, "GitHub 通知処理中にエラーが発生しました: #{error}"

    res.end ""

repo2rooms = (robot, repo) ->
  m = (robot.brain.get("gh-notify-repository-to-rooms") || {})
  return (m[repo] || [])

unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

extract_mentions = (robot, body) ->
  if body
    mentioned = body.match(/(^|\s)(@[\w\-\/]+)/g)
  else
    return []

  if mentioned
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
    mentioned
  else
    []

ellipsisize = (str, num) ->
  lines = (str || "").split("\n")
  header = lines.slice(0, num)
  buff = header.map (l) -> "> " + l
               .join("\n")
  quotes = buff.match(/```/g)
  if (quotes && quotes.length % 2) == 1
    buff += "\n```"
  if lines.slice(num).length > 0
    buff += "\n..."
  return buff

announcePullRequest = (robot, data, cb) ->
  switch data.action
    when 'opened'
      mentioned = extract_mentions(robot, data.pull_request.body)

      if mentioned.length > 0
        mentioned_line = "\n> Mentioned: #{mentioned.join(", ")}"
      else
        mentioned_line = ''

      cb "PR が作成されました \"#{data.pull_request.title}\" by #{data.pull_request.user.login}\n#{data.pull_request.html_url}#{mentioned_line}\n#{ellipsisize(data.pull_request.body, 4)}"

    when "synchronize"
      cb "PR にコミットが追加pushされました \"#{data.pull_request.title}\"\n#{data.pull_request.html_url}"

    when "closed"
      cb "PR が close されました \"#{data.pull_request.title}\" by #{data.pull_request.merged_by?.login}\n#{data.pull_request.html_url}"

announcePullRequestReviewComment = (robot, data, cb) ->
  switch data.action
    when 'created'
      mentioned = extract_mentions(robot, data.comment.body)

      if mentioned.length > 0
        mentioned_line = "\n> Mentioned: #{mentioned.join(", ")}"
      else
        mentioned_line = ''

      cb "\"#{data.pull_request.title}\" コメント追加 by #{data.comment.user.login}\n#{data.comment.html_url}#{mentioned_line}\n#{ellipsisize(data.comment.body, 4)}"

announceIssue = (robot, data, cb) ->
  switch data.action
    when 'opened'
      mentioned = extract_mentions(robot, data.issue.body)

      if mentioned.length > 0
        mentioned_line = "\n> Mentioned: #{mentioned.join(", ")}"
      else
        mentioned_line = ''

      cb "Issue が作成されました \"#{data.issue.title}\" by #{data.issue.user.login}\n#{data.issue.html_url}#{mentioned_line}\n#{ellipsisize(data.issue.body, 4)}"

    when "closed"
      cb "Issue が close されました \"#{data.issue.title}\" by #{data.sender.login}\n#{data.issue.html_url}"

announceIssueComment = (robot, data, cb) ->
  switch data.action
    when 'created'
      mentioned = extract_mentions(robot, data.comment.body)
      if mentioned.length > 0
        mentioned_line = "\n> Mentioned: #{mentioned.join(", ")}"
      else
        mentioned_line = ''
      cb "\"#{data.issue.title}\" コメント追加 by #{data.comment.user.login}\n#{data.comment.html_url}#{mentioned_line}\n#{ellipsisize(data.comment.body, 4)}"
