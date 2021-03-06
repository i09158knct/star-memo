express  = require 'express'
http     = require 'http'
path     = require 'path'
mongoose = require 'mongoose'
settings = require './settings'

require './models/event'
require './models/repo'
require './models/star'

mongoose.connect settings.dbhost, settings.dbname
app = express()



# Configuring
do ->
  app.configure ->
    app.set 'port', 9999
    app.set 'views', (path.join __dirname, 'views')
    app.set 'view engine', 'jade'
    app.use require('connect-assets')()
    app.use express.favicon()
    app.use express.logger 'dev'
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use app.router
    app.use express.static (path.join __dirname, 'public')


  app.configure 'development', ->
    app.use express.errorHandler()



# Route setting
do ->
  require('./controllers/home')(app)
  require('./controllers/stars')(app)



# Server starting
do ->
  port = app.get 'port'
  http.createServer(app).listen port, ->
    console.log "Express server litening on port #{port}"
