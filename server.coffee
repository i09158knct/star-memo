express  = require 'express'
http     = require 'http'
path     = require 'path'

mongoose = require 'mongoose'
mongoose.connect 'localhost', 'tmp'



app = express()
app.configure () ->
  app.set 'port', 9999
  app.set 'views', path.join __dirname, 'views'
  app.set 'view engine', 'jade'
  app.use require('connect-assets')()
  app.use express.favicon()
  app.use express.logger 'dev'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static path.join __dirname, 'public'


app.configure 'development', () ->
  app.use express.errorHandler()



router = require './routes/router'
router(app)
rpc = require './routes/rpc'
rpc(app)


port = app.get 'port'
http.createServer(app).listen port, () ->
  console.log "Express server litening on port #{port}"
