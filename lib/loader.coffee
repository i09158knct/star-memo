settings     = require '../settings'
GitHubLoader = require 'gh-loader'

module.exports = new GitHubLoader
  username: settings.username
  clientId: settings.clientId
  clientSecret: settings.clientSecret
