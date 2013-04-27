mongoose = require 'mongoose'


repoSchema = new mongoose.Schema
  id: String
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


# repoSchema.set 'autoIndex', false

module.exports = mongoose.model 'Repo', repoSchema
