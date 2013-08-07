mongoose = require 'mongoose'

# Tasks
articleSchema = mongoose.Schema
  title: String
  url: String
  source: String
  pubDate: { type: Date, default: Date.now }
  description: String
  keywords: Array

exports.Article = Article = mongoose.model('Article', articleSchema)

logSchema = mongoose.Schema
  timestamp: { type: Date, default: Date.now }
  text: String

exports.Log = Log = mongoose.model('Log', logSchema)