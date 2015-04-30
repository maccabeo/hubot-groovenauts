# Description:
#   Manupilate GitHub repository.
#
# Dependencies:
#   "githubot": "0.5.x"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_API
#
# Commands:
#   hubot github show repos -- デフォルトの対象リポジトリ一覧表示
#   hubot github add repo <repo> -- デフォルトの対象リポジトリに <repo> を追加
#   hubot github remove repo <repo> -- デフォルトの対象リポジトリから <repo> を削除
#   hubot github show {PR,pull req} [no-wip] [<repo>] -- GitHub の open な pull request 一覧
#   hubot github show issue[s] -- GitHub の open な issue 一覧
#
# Notes:
#   HUBOT_GITHUB_API allows you to set a custom URL path (for Github enterprise users)
#
#   You can further filter pull request title by providing a regular expression.
#   For example, `show me hubot pulls with awesome fix`.
#
# Author:
#   jingweno

module.exports = (robot) ->

  github = require("githubot")(robot)

  github.handleErrors (response) ->
    robot.logger.error "Oh no! #{response.statusCode}: #{response.error}!\n"
    robot.logger.error response.body

  unless (url_api_base = process.env.HUBOT_GITHUB_API)?
    url_api_base = "https://api.github.com"

  removeDuplicates = (ary) ->
    if ary.length == 0
      return []
    res = []
    res[ary[key]] = ary[key] for key in [0..ary.length-1]
    value for key, value of res

  robot.respond /github\s+show\s+repos\s*$/i, (msg) ->
    repos = robot.brain.get("github_default_target_repos")
    unless repos
      repos = []
    list = "GitHub の以下のリポジトリがデフォルトの対象です:\n"
    for repo in repos
      list += "#{repo}\n"
    msg.send list

  robot.respond /github\s+add\s+repo\s+([a-z0-9._/-]+)\s*$/i, (msg) ->
    repo = github.qualified_repo msg.match[1]
    github.get "#{url_api_base}/repos/#{repo}", (ok) ->
      repos = robot.brain.get("github_default_target_repos")
      unless repos
        repos = []
      repos.push repo
      robot.brain.set("github_default_target_repos", removeDuplicates(repos))
      msg.send "対象のリポジトリに #{repo} を追加しました"

  robot.respond /github\s+remove\s+repo\s+([a-z0-9._/-]+)\s*$/i, (msg) ->
    repo = github.qualified_repo msg.match[1]
    github.get "#{url_api_base}/repos/#{repo}", (ok) ->
      repos = robot.brain.get("github_default_target_repos")
      unless repos
        repos = []
      repos = removeDuplicates(repos).filter (v) ->
        v != repo
      robot.brain.set("github_default_target_repos", repos)
      msg.send "対象のリポジトリから #{repo} を削除しました"

  robot.respond /github\s+show\s+(PRs?|pull\s+req(uests?)?)(\s+no-wip)?\s*([a-z0-9._/-]+)?$/i, (msg)->
    nowip = msg.match[3]
    repo = msg.match[4]
    if repo
      repos = []
      for r in repo.split(",")
        repos.push(r)
    else
      repos = robot.brain.get("github_default_target_repos")
      unless repos
        repos = []

    for repo in repos
      cb = (repo) ->
        github.get "#{url_api_base}/repos/#{repo}/pulls", (pulls) ->
          if pulls.length == 0
            summary = "#{repo}: マージ待ちの pull request はありません :+1:"
          else
            summary = "#{repo}: pull request 一覧\n"
            for pull in pulls
              if nowip && pull.title.indexOf("[WIP]") > -1
                continue
              mentioned = []
              pull.body.replace /\[ \]\s*(@[a-z0-9_-]+)/gi, (match, nick) ->
                mentioned.push(nick)
                match
              mentioned = mentioned.map (nick) ->
                for _uid, user of robot.brain.users()
                  if "@#{user.githubLogin}" == nick
                    nick = "@#{user.name}"
                    break
                "<#{nick}>"
              if mentioned.length > 0
                mentioned = ": " + mentioned.join(", ")
              else
                mentioned = ""
              # cannot use label for a link see: https://github.com/slackhq/hubot-slack/issues/114
              summary += "\n\t#{pull.html_url} #{pull.title} - #{pull.user.login}#{mentioned}\n"
          msg.send summary
      cb(repo)

  robot.respond /github\s+show\s+issues?\s*([a-z0-9._/-]+)?$/i, (msg)->
    repos = msg.match[3]
    if repos
      repos = []
      for r in repo.split(",")
        repos.push(r)
    else
      repos = robot.brain.get("github_default_target_repos")
      unless repos
        repos = []

    for repo in repos
      cb = (repo) ->
        github.get "#{url_api_base}/repos/#{repo}/issues?state=open", (issues) ->
          if issues.length == 0
            summary = "#{repo}: issue はありません :+1:"
          else
            summary = "#{repo}: issue 一覧\n"
            for issue in issues
              continue if issue.html_url.match(/\/pulls?\//)
              # cannot use label for a link see: https://github.com/slackhq/hubot-slack/issues/114
              summary += "\n\t#{issue.html_url} #{issue.title} - #{issue.user.login}\n"
          msg.send summary
      cb(repo)
