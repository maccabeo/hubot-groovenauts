# references:
#   http://devlog.forkwell.com/2014/10/28/testable-hubot-tdddetesutowoshu-kinagarabotwozuo-ru/
#   http://ja.ngs.io/2014/06/13/tdd-hubot-scripts/
#

chai = require("chai")
nock = require("nock")
{ expect } = chai

Robot       = require('hubot/src/robot')
TextMessage = require('hubot/src/message').TextMessage

describe "GitHub Operation", ->
  robot = null
  user = null
  adapter = null

  beforeEach (done) ->
    nock.disableNetConnect()
    nock("https://api.github.com").get("/repos/example/test").reply(200)
    robot = new Robot(null, "mock-adapter", yes, "hubot")
    robot.adapter.on "connected", ->
      require("../scripts/github-account-map")(robot)
      require("../scripts/github-op")(robot)
      user = robot.brain.userForId '1',
        name: 'mocha'
        room: '#mocha'
      adapter = robot.adapter
      done()
    robot.run()

  afterEach ->
    robot.server.close()
    robot.shutdown()
    nock.cleanAll()

  it "github show repos", (done) ->
    adapter.on "send", (envelope, strings) ->
      expect(envelope.user.name).to.equal("mocha")
      expect(strings[0]).to.equal("GitHub の以下のリポジトリがデフォルトの対象です:\n")
      done()

    adapter.receive(new TextMessage(user, "hubot github show repos"))

  it "github add repo", (done) ->
    adapter.on "send", (envelope, strings) ->
      expect(envelope.user.name).to.equal("mocha")
      expect(strings[0]).to.equal("対象のリポジトリに example/test を追加しました")
      done()

    adapter.receive(new TextMessage(user, "hubot github add repo example/test"))

