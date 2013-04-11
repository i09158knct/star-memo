mongoose = require 'mongoose'

{Mixed} = mongoose.Schema.Types

eventSchema = new mongoose.Schema
  type: String
  actor: Mixed
  repo: Mixed
  payload: Mixed
  read:
    type: Boolean
    default: false
  created_at:
    type: Date

# eventSchema.index

# eventSchema.set 'autoIndex', false

module.exports = mongoose.model 'Event', eventSchema

