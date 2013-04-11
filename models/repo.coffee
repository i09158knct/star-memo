mongoose = require 'mongoose'


repoSchema = new mongoose.Schema
  repo_id: String
  name: String
  owner:
    login: String
    user_id: String
  html_url: String
  homepage: String
  description: String

  watchers: Number
  forks_count: Number
  language: String
  created_at: Date
  updated_at: Date

repoSchema.index
  repo_id: 1

# repoSchema.set 'autoIndex', false

module.exports = mongoose.model 'Repo', repoSchema
