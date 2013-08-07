FeedParser = require 'feedparser'
request = require 'request'
fs = require 'fs'

feeds = 

  # Variety
  varietyFrontPage:         'http://feeds.feedburner.com/variety/news/frontpage'
  varietyHeadlines:         'http://feeds.feedburner.com/variety/headlines'
  varietyFilmNews:          'http://feeds.feedburner.com/variety/news/film'
  varietyWeekendBoxOffice:  'http://feeds.feedburner.com/variety/boxofficeandratings/weekendbo'
  varietyFilmReviews:       'http://feeds.feedburner.com/variety/reviews/film'

  # IndieWire
  indiewireBoxOffice:       'http://feeds.feedburner.com/indieWIREBoxOffice'
  indiewireFestivals:       'http://feeds.feedburner.com/indieWIREFesitvals'
  indiewireFilmmakerToolkit:'http://feeds.feedburner.com/indieWIREFilmmakerToolkit'
  indiewireProjectOfTheDay: 'http://feeds.feedburner.com/indiewire/ProjectoftheDay'

  # NYTimes
  nytimesBusines:           'http://rss.nytimes.com/services/xml/rss/nyt/Business.xml'
  nytimesMovies:            'http://rss.nytimes.com/services/xml/rss/nyt/Movies.xml'

  # the Wrap
  theWrapLatest:            'http://www.thewrap.com/rss/latest'

  # Deadline
  deadline:                 'http://www.deadline.com/feed/rss/'

  # Hollywood Reporter
  #   feeds: http://www.hollywoodreporter.com/rss
  hollywoodReporterMovies:  'http://feeds.feedburner.com/thr/film'
  hollywoodReporterBO:      'http://feeds.feedburner.com/thr/boxoffice'
  hollywoodReporterReviews: 'http://feeds.feedburner.com/thr/reviews/film'
  hollywoodReporterBusiness:'http://feeds.feedburner.com/thr/business'

  # Screen Daily
  #   feeds: http://www.screendaily.com/home/rss/
  screenDailyLatestNews:    'http://www.screendaily.com/XmlServers/navsectionRSS.aspx?navsectioncode=3'
  screenDailyProductionNews:'http://www.screendaily.com/XmlServers/navsectionRSS.aspx?navsectioncode=279'


# Load external keywords file
# currently a list of Slated members, films and companies that Steph tracks
keywords = JSON.parse(fs.readFileSync('./keywords.json'))


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
      # console.log meta.title, meta.xmlurl or meta.xmlUrl
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

exports.getFeeds = getFeeds

# Let's go!
getFeeds()

# Called when all the feeds have been requested and parsed
completed = ->
  searchKeywords()


# Keyword searching ==============================================

arrayToLowerCase = (list) ->
  lowerList = []
  lowerList.push item.toLowerCase() for item in list
  return lowerList

keywordsRegex = (list) ->
  regexList = []
  regexList.push new RegExp(keyword, 'gi') for keyword in list
  return regexList

results = {}

# Run through the articles and match all the keywords
# NOTE: jsperf says regex much faster than toLowerCase + indexOf
searchKeywords = ->
  keywordRegEx = keywordsRegex(keywords)
  for article in articles
    searchText = article.title + article.description
    for regex, i in keywordRegEx
      if searchText.match(regex)
        if not results[article.link]
          article.matchingKeywords = [ keywords[i] ]
          results[article.link] = article
        else
          results[article.link].matchingKeywords.push(keywords[i])

  writeToFile(results)


# takes a results object
writeToFile = (results) ->
  fileName = new Date().toLocaleString().replace(/\ /g, '_')
  json = JSON.stringify(results, null, '\t')
  matches = Object.keys(results).length
  fs.writeFile("../results/#{fileName}.json", json, (err) ->
    console.error err if err
    console.log """
      #{feedsComplete} feeds searched with #{matches} matches
      New file created: #{fileName}.json
      """
  )


