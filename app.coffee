express = require 'express'
mongoose = require 'mongoose'

app = express()

app.configure ->
  app.use(express.logger('dev'))
  app.use(express.bodyParser())


app.get '/', (req, res) ->
  res.json({ status: true })





port = process.env.PORT or 3000
app.listen(port)
console.log "Listening on port #{port}"