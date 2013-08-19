express = require 'express'
mongoose = require 'mongoose'
fs = require 'fs'
path = require 'path'

models = require './lib/models.coffee'
runner = null

# Mongo 
mongoose.connect(process.env.MONGOHQ_URL or 'mongodb://localhost/rssrunner')

db = mongoose.connection
db.on('error', console.error.bind(console, 'connection error:'))
db.once('open', ->
  console.log "Database connection successful"
  runner = require './lib/runner.coffee'
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
  # models.Article.find().sort({ pubDate: -1 }).exec( (err, data) ->
  #   return handleError(err) if err

  #   res.render('feed',
  #     articles: data
  #   )
  # )
  res.render('feed', {})

# the feed in json format
app.get '/articles', (req, res) ->
  
  offset = if req.query.offset and not isNaN(req.query.offset) then parseInt(req.query.offset, 10) else 0

  models.Article.find({ archived: { $ne: true }}).sort({ pubDate: -1 }).skip(offset).limit(20).exec( (err, data) ->
    return handleError(err) if err
    res.json(data)
  )

# Get a single article
app.get '/articles/:id', (req, res) ->
  models.Article.findOne({ _id: req.params.id }, (err, article) ->
    return handleError(err) if err

    res.json(article)
  )

# Hide/Remove an article from the list
app.delete '/articles/:id', (req, res) ->
  console.log "DELETE:", req.params.id
  models.Article.update({ _id: req.params.id }, { archived: true }, (err, numberEffected) ->
    return handleError(err) if err
    console.log "#{numberEffected} Updated"
    res.json(true)
  )

# app.delete '/articles/:id', (req, res) ->
#   console.log "DELETE:", req.params.id
#   models.Article.update({ _id: req.params.id }, { archived: true }, (err, numberEffected) ->
#     return handleError(err) if err
#     console.log "#{numberEffected} Updated"
#     res.json(true)
#   )

# app.get '/articles/:id', (req, res) ->
#   models.Article.findOne({ _id: req.params.id }, (err, article) ->
#     return handleError(err) if err

#     res.render('feed',
#       articles: [ article ]
#     )
#   )
# ...and in JSON format


  
# List all keywords currently being matched
app.get '/keywords', (req, res) ->
  fs.readFile(path.join(__dirname, './keywords.json'), (err, keywords) ->
    return handleError(err) if err
    res.json(JSON.parse(keywords))
    )

# List all feeds currently being sourced
app.get '/feeds', (req, res) ->
  feeds = require './lib/feeds.coffee'
  res.json(feeds)

# List all feeds currently being sourced
app.get '/log', (req, res) ->
  models.Log.find().limit(20).sort({ timestamp: -1 }).exec( (err, logData) ->
    return handleError(err) if err

    res.render('log',
      log : logData
    )
  )

# run the script via get request
app.get '/run', (req, res) ->
  models.Log.findOne().sort({ timestamp: -1 }).exec( (err, entry)->

    tenMinAgo = new Date()
    tenMinAgo.setMinutes(tenMinAgo.getMinutes() - 10)

    # if it had been run more than 10 min ago, run the script
    if entry.timestamp < tenMinAgo and runner
      runner.getFeeds()
      status = "Running...check back in a couple min"

    res.render('log',
      status: status or "Wait a few minutes..."
    )
  )


port = process.env.PORT or 3000
app.listen(port)
console.log "Listening on port #{port}"
