# Description:
#   Replies with a random post from a subreddit
#
# Dependencies:
#   None
#
# Configuration:
#   subreddit_aliases.json
#   HUBOT_SUBREDDIT_ALIASES
#
# Commands:
#   hubot sub me SUBREDDIT - Get a post from the given subreddit
#   hubot sub me top SUBREDDIT - Get a post from the top of all time from the given subreddit
#   hubot sub me top week SUBREDDIT - Get a post from the top of the week from the given subreddit
#   hubot SUBREDDIT_ALIAS me - Get a post from the aliased subreddit

url = require("url")
fs = require("fs")

sendRandomPost = (msg, subreddit, sort, time) ->
  query = if time then "?t=#{time}" else ""
  msg.http("https://www.reddit.com/r/#{subreddit}/#{sort}.json#{query}")
    .get() (err, resp, body) ->
      if resp.statusCode == 302 # redirects to search on subreddit not found
        msg.send "Subreddit not found"
        return

      if resp.statusCode == 403
        msg.send "Subreddit is private"
        return

      result = JSON.parse(body)

      urls = [ ]
      for child in result.data.children
        if child.data.domain != "self.#{subreddit}"
          urls.push(child.data.url)

      if urls.count <= 0
        msg.send "Couldn't find anything..."
        return

      rnd = Math.floor(Math.random() * urls.length)
      picked_url = urls[rnd]

      parsed_url = url.parse(picked_url)
      if parsed_url.host == "imgur.com"
        parsed_url.host = "i.imgur.com"
        parsed_url.pathname = parsed_url.pathname + ".jpg"

        picked_url = url.format(parsed_url)

      msg.send picked_url

module.exports = (robot) ->
  aliases = {}

  if process.env.HUBOT_SUBREDDIT_ALIASES
    subs = process.env.HUBOT_SUBREDDIT_ALIASES.split(',')
    for sub in subs
      [alias, subreddit] = sub.replace(/^\s*|\s*$/g, '').split(':')
      aliases[alias] = subreddit

  else if fs.existsSync 'subreddit_aliases.json'
    file = fs.readFileSync 'subreddit_aliases.json', 'utf8'
    aliases = JSON.parse(file)

  for alias, subreddit of aliases
    robot.respond "/#{alias}( me)?/i", (msg) -> sendRandomPost(msg, subreddit)

  robot.respond /sub(?: me)?( top)? ?(all|year|month|week|day)? (\S*)/i, (msg) ->
    sort = if msg.match[1] then 'top' else 'hot'
    time = msg.match[2]
    subreddit = msg.match[3]
    sendRandomPost(msg, subreddit, sort, time)

