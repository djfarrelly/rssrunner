fs = require 'fs'
path = require 'path'

FeedParser = require 'feedparser'
request = require 'request'
mongoose = require 'mongoose'

models = require './models.coffee'
feeds = require './feeds.coffee'


# Load external keywords file
# currently a list of Slated members, films and companies that Steph tracks
keywords = JSON.parse(fs.readFileSync(path.join(__dirname, '../keywords.json')))


# Keyword searching ==============================================

keywordsRegex = (list) ->
  regexList = []
  regexList.push new RegExp(keyword, 'gi') for keyword in list
  return regexList



# Run through the articles and match all the keywords
# NOTE: jsperf says regex much faster than toLowerCase + indexOf
searchKeywords = ->
  results = {}
  keywordRegEx = keywordsRegex(keywords)

  for article, i in articles
    searchText = article.title + article.description
    for regex, j in keywordRegEx
      
      if searchText.match(regex)
        if not results[article.link]
          results[article.link] =
            article: article
            keywords: [ keywords[j] ]
        else if results[article.link].keywords
          results[article.link].keywords.push(keywords[j])

  addResultsToDB(results, (err, newArticles) ->
    console.error "Error adding articles to the db", err if err

    logEntryText = "Found #{newArticles} new matching articles.  #{Object.keys(results).length} existing matches."
    models.Log.create(
      text: logEntryText
    , (err, logEntry) ->
      console.error err if err
      console.log logEntry.text
    )

    closeDB()
  )


addResultsToDB = (results, done) ->
  complete = 0
  newArticles = 0
  for articleUrl, data of results
    addMatchingArticle(data.article, data.keywords, (err, newArticleAdded) ->
      done(err) if typeof done == 'function' and err
      complete += 1
      newArticles += 1 if newArticleAdded
      done(null, newArticles) if typeof done == 'function' and complete == Object.keys(results).length
      )


addMatchingArticle = (article, keywords, done) ->
  models.Article.findOne({ url: article.link }, (err, existingArticle) ->
    console.error "Error finding article" if err

    if existingArticle
      # Article exists in the DB, add keywords
      for newKeyword in keywords
        if existingArticle.keywords.indexOf(newKeyword) == -1
          existingArticle.keywords.push(newKeyword)
      existingArticle.save()
      done(null, false) if typeof done == 'function'
    else
      # Create the article
      models.Article.create(
        url: article.link
        title: article.title
        source: "#{article.meta.title} | #{article.meta.description}"
        description: article.description
        pubDate: article.pubDate
        keywords: keywords
      , (err, newArticle) ->
        if typeof done == 'function'
          if err
            done(err)
          else
            done(null, true)
      )
    )


# To check that all feeds are complete
feedCount = Object.keys(feeds).length
feedsComplete = 0

articles = []

# Get a feed a push it onto the log array
getFeed = (url) ->
  request(url)
    .on('error', (err) -> console.error err )
    .pipe(new FeedParser)
    .on('error', (err) -> console.error err )
    .on('meta', (meta) ->
      console.log meta.title, meta.xmlurl or meta.xmlUrl
    )
    .on('readable', ->
      while item = this.read()
        articles.push item
    )
    .on('end', ->
      feedsComplete += 1
      completed() if feedsComplete >= feedCount
    )

# Get all the feeds in the feed dict
getFeeds = ->
  for feed, url of feeds
    getFeed(url)

# Called when all the feeds have been requested and parsed
completed = ->
  searchKeywords()

# Let's go!
# getFeeds()


findAndClose = ->
  models.Article.find( (err, data) ->
    throw Error() if err
    console.log "ARTICLES:::\n\n", data

    closeDB()
  )  

closeDB = ->
  # close DB connection only if it was created
  if db
    console.log "Closing DB Connection in 5 seconds..."
    setTimeout( ->
      db.close( ->
        console.log "Database connection closed."
        )
    , 5000)


# Mongo 
if not mongoose.connection.db
  mongoose.connect(process.env.MONGOHQ_URL or 'mongodb://localhost/rssrunner')
  db = mongoose.connection
  db.on('error', console.error.bind(console, 'connection error:'))
  db.once('open', ->
    console.log "Database connection successful"
    getFeeds()
  )

else
  console.log "Database connection already established"
  getFeeds()


