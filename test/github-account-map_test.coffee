chai = require("chai")
{ expect } = chai

Robot       = require('hubot/src/robot')
TextMessage = require('hubot/src/message').TextMessage

describe "GitHub Account Map", ->
  robot = null
  user = null
  adapter = null

  beforeEach (done) ->
    robot = new Robot(null, "mock-adapter", yes, "hubot")
    robot.adapter.on "connected", ->
      require("../scripts/github-account-map")(robot)
      user = robot.brain.userForId '1',
        name: 'mocha'
        room: '#mocha'
      adapter = robot.adapter
      done()
    robot.run()

  afterEach ->
    robot.server.close()
    robot.shutdown()

  it "GitHub アカウント記憶", (done) ->
    adapter.on "send", (envelope, strings) ->
      expect(envelope.user.name).to.equal("mocha")
      expect(strings[0]).to.equal("@mocha の GitHub でのアカウントは mocho ですね: https://github.com/mocho")
      expect(robot.brain.userForId('1').githubLogin).to.equal("mocho")
      done()

    adapter.receive(new TextMessage(user, "hubot わたしの GitHub アカウントは mocho です"))

