# Description:
#   Wish list, and reminder for the whole chatroom
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot wa <message>       # Add entry to wish list
#   hubot wr <id>            # remove entry by their ID
#   hubot wl                 # list all existing wishes
#   hubot wt <id>            # take wishlist and indicate a 'DOING' action in a message
#
# Author:
#   tone


class Reminders
  constructor: (@robot) ->
    @cache = []
    @current_timeout = null
    @runningNo = 1

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.wishList
        @cache = @robot.brain.data.wishList
        #@cache.splice(0, @cache.length)
        if @cache.length > 0
          @runningNo = @cache[@cache.length - 1].runningNo + 1
      @robot.brain.data.wishList = @cache

  add: (wish) ->
    wish.runningNo = @runningNo
    @cache.push wish
    @robot.brain.data.wishList = @cache
    @runningNo += 1

  removeElement: (id) ->
    wishList = @listing()
    for key of wishList
      if (wishList[key].runningNo is parseInt(id, 10) )
        return wishList.splice(key, 1)
    return [];

  listing: ->
    wishList = @robot.brain.data.wishList
    return wishList

  removeFirst: ->
    reminder = @cache.shift()
    @robot.brain.data.reminders = @cache
    return reminder

  queue: ->
    clearTimeout @current_timeout if @current_timeout
    if @cache.length > 0
      now = new Date().getTime()
      @removeFirst() until @cache.length is 0 or @cache[0].due > now
      if @cache.length > 0
        trigger = =>
          reminder = @removeFirst()
          @robot.send reminder.for, reminder.for.name + ', you asked me to remind you to ' + reminder.action
          @queue()
        @current_timeout = setTimeout trigger, @cache[0].due - now

  handleListing: (msg) ->
    wishList = @listing()

    #msg.send 'Total wish(es) : ' + wishList.length

    for wish of wishList
        msg.send wishList[wish].runningNo + ']: ' + wishList[wish].msg

  handleRemove: (msg, id) ->
    wishList = @listing()
    success = @removeElement(id)
    if success.length > 0
      msg.send 'Wish removed -> ' + success[0].msg

  handleTake: (msg, id, userName) ->
    wishList = @listing()
    for key of wishList
      if (wishList[key].runningNo is parseInt(id, 10) )
        wishMsg = wishList[key].msg
        wishMsg = '* ' + userName + ' is TAKING * : ' + wishMsg
        wishList[key].msg = wishMsg
        msg.send wishMsg

class Reminder
  constructor: (msg) ->
    @msg = msg

  msg: ->
    return @msg
  
module.exports = (robot) ->

  reminders = new Reminders robot

  robot.respond /wa (.*)/i, (msg) ->
    wishMsg = msg.match[1].trim()
    wish = new Reminder wishMsg
    wish.msg = wish.msg + ' #' + msg.message.user.name
    reminders.add(wish)
    msg.send "Added"

  robot.hear /-wa (.*)/i, (msg) ->
    wishMsg = msg.match[1].trim()
    wish = new Reminder wishMsg
    wish.msg = wish.msg + ' #' + msg.message.user.name
    reminders.add(wish)
    msg.send "Added"

  robot.respond /wl/i, (msg) ->
    reminders.handleListing(msg)

  robot.hear /-wl/i, (msg) ->
    reminders.handleListing(msg)

  robot.respond /wr (.*)/i, (msg) ->
    id = msg.match[1].trim()
    reminders.handleRemove(msg, id)

  robot.hear /-wr (.*)/i, (msg) ->
    id = msg.match[1].trim()
    reminders.handleRemove(msg, id)

  robot.respond /wt (.*)/i, (msg) ->
    id = parseInt(msg.match[1].trim(), 10)
    reminders.handleTake(msg, id, msg.message.user.name)

  robot.hear /-wt (.*)/i, (msg) ->
    id = parseInt(msg.match[1].trim(), 10)
    reminders.handleTake(msg, id, msg.message.user.name)



