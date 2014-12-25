# Description:
#   GitHub の WebHook から Pull Request の通知を受ける
#
# Dependencies:
#   "url": ""
#   "querystring": ""
#
# Configuration:
#   You will have to do the following:
#   1. Get an API token: curl -u 'username' -d '{"scopes":["repo"],"note":"hubot"}' \
#                         https://api.github.com/authorizations
#   2. Add <HUBOT_URL>:<PORT>/hubot/gh-pull-requests url hook via API:
#      curl -H "Authorization: token <your api token>" \
#      -d '{"name":"web","active":true,"events":["pull_request"],"config":{"url":"<this script url>","content_type":"json"}}' \
#      https://api.github.com/repos/<your user>/<your repo>/hooks
#
# Commands:
#   hubot github pull requests notify <repo> <room> -- <repo> の pull request を <room> に通知する
#   hubot github pull requests notify show -- pull request の通知先 room を表示
#
# URLS:
#   POST /hubot/gh-pull-requests
#
# Authors:
#   nagachika


url = require('url')
querystring = require('querystring')

module.exports = (robot) ->
  robot.respond /github\s+pull\s+requests\s+notify\s+([a-z0-9_./-]+)\s+([^\s]+)\s*$/, (msg) ->
    repo = msg.match[1]
    room = msg.match[2]
    m = (robot.brain.get("gh-pull-requests-repository-to-rooms") || {})
    r = (m[repo] || [])
    r.push(room)
    m[repo] = r
    robot.brain.set("gh-pull-requests-repository-to-rooms", m)

  robot.router.post "/hubot/gh-pull-requests", (req, res) ->
    data = req.body
    repo = data.repository.full_name

    for room in repo2rooms(robot, repo)
      try
        announcePullRequest data, (what) ->
          robot.messageRoom room, what
      catch error
        robot.messageRoom room, "Whoa, I got an error: #{error}"
        console.log "github pull request notifier error: #{error}. Request: #{req.body}"

    res.end ""

repo2rooms = (robot, repo) ->
  m = (robot.brain.get("gh-pull-requests-repository-to-rooms") || {})
  return (m[repo] || [])

announcePullRequest = (data, cb) ->
  if data.action == 'opened'
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

      mentioned_line = "\nMentioned: #{mentioned.join(", ")}"
    else
      mentioned_line = ''

    cb "New pull request \"#{data.pull_request.title}\" by #{data.pull_request.user.login}: #{data.pull_request.html_url}#{mentioned_line}"
