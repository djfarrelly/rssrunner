express = require 'express'
mongoose = require 'mongoose'
fs = require 'fs'
path = require 'path'

models = require './src/models.coffee'

# Mongo 
mongoose.connect(process.env.MONGOHQ_URL or 'mongodb://localhost/rssrunner')

db = mongoose.connection
db.on('error', console.error.bind(console, 'connection error:'))
db.once('open', ->
  console.log "Database connection successful"
)


# Express
app = express()

handleError = (err) ->
  console.error err
  res(404, 'Something happened on the way to heaven...')

app.configure ->
  app.use(express.logger('dev'))
  app.use(express.bodyParser())
  app.use(express.static(__dirname + '/public'))
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')


app.get '/', (req, res) ->
  models.Article.find( (err, data) ->
    return handleError(err) if err

    res.render('feed',
      { articles : data }
    )
  )

# the feed in json format
app.get '/json', (req, res) ->
  models.Article.find( (err, data) ->
    return handleError(err) if err

    res.json(data)
  )
  
# List all keywords currently being matched
app.get '/keywords', (req, res) ->
  fs.readFile(path.join(__dirname, './keywords.json'), (err, keywords) ->
    return handleError(err) if err
    res.json(JSON.parse(keywords))
    )

# List all feeds currently being sourced
app.get '/feeds', (req, res) ->
  feeds = require './src/feeds.coffee'
  res.json(feeds)

# List all feeds currently being sourced
app.get '/log', (req, res) ->
  models.Log.find( (err, data) ->
    return handleError(err) if err

    res.render('log',
      log : data
      mongoURL: process.env.MONGOHQ_URL
    )
  )


app.get '/run', (req, res) ->
  runner = require './src/runner.coffee'
  res.send("running...")


port = process.env.PORT or 3000
app.listen(port)
console.log "Listening on port #{port}"