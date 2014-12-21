# Description:
#   GitHub Account Map allows you to map your user against your GitHub user.
#   This is specifically in order to work with apps that have GitHub Oauth users.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot GitHub アカウント一覧 - List all the users with github logins tracked by Hubot
#   hubot わたしはGitHubでは`nagachika`です - map your user to the github login `nagachika`
#   hubot わたしのGitHubアカウントは? - reveal your mapped github login
#
# Author:
#   nagachika

module.exports = (robot) ->

  robot.respond /GitHub\s*(ユーザー?|アカウント)一覧$/i, (msg) ->
    theReply = "GitHubアカウント一覧です:\n"

    for own key, user of robot.brain.users()
      if user.githubLogin
        theReply += "@#{user.name} → #{user.githubLogin}\n"

    msg.send theReply

  robot.respond /(わたし|私|僕|オレ|おれ|俺)\s*(は|の)\s*GitHub\s*(では|アカウントは?)\s*([a-z0-9-]+)\s*(です)?$/i, (msg) ->
    githubLogin = msg.match[4]
    msg.message.user.githubLogin = githubLogin
    msg.send "@#{msg.message.user.name} の GitHub でのアカウントは #{githubLogin} ですね: https://github.com/#{githubLogin}"

  robot.respond /(わたし|私|僕|オレ|おれ|俺)\s*(は|の)\s*GitHub\s*アカウント(は?\?)?\s*$/i, (msg) ->
    user = msg.message.user
    if user.githubLogin
      msg.reply "@#{msg.message.user.name} の GitHub でのアカウントは #{user.githubLogin} です https://github.com/#{user.githubLogin}"
    else
      msg.reply "すみません、@#{msg.message.user.name} の GitHub アカウントはまだ知りません"
