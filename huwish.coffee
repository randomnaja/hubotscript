# Description:
#   Wish list, and reminder for the whole chatroom
#
# Dependencies:
#   None
#
# Configuration:
#   HUWISH_STORAGE_KEY
#
# Commands:
#   hubot wa <message>       # Add entry to wish list
#   hubot wr <id>            # remove entry by their ID
#   hubot wl                 # list all existing wishes
#   hubot wt <id>            # take a wish and indicate a 'DOING' action in a message
#   hubot wu <id>            # UN-take a wish
#
# Author:
#   tone

class Reminders
  constructor: (@robot) ->
    @cache = []
    @current_timeout = null
    @runningNo = 1
    @storageKey

    @robot.brain.on 'loaded', =>
      @storageKey = process.env.HUWISH_STORAGE_KEY or 'wishList'
      if @robot.brain.data[@storageKey]
        @cache = @robot.brain.data[@storageKey]
        #@cache.splice(0, @cache.length)
        if @cache.length > 0
          @runningNo = @cache[@cache.length - 1].runningNo + 1
      @robot.brain.data[@storageKey] = @cache

  add: (wish) ->
    wish.runningNo = @runningNo
    @cache.push wish
    #@robot.brain.data.wishList = @cache
    @runningNo += 1
    return wish.runningNo

  removeElement: (id) ->
    wishList = @listing()
    for key of wishList
      if (wishList[key].runningNo is parseInt(id, 10) )
        return wishList.splice(key, 1)
    return [];

  listing: ->
    wishList = @robot.brain.data[@storageKey]
    return wishList

  handleListing: (msg) ->
    wishList = @listing()
    for wish of wishList
        wishObj = wishList[wish]
        @handleDisplayWish(wishObj, msg)

  handleDisplayWish: (wishObj, msg) ->
    msg.send @formatWish(wishObj)

  formatWish: (wishObj) ->
    takingMsg = if wishObj.taking then '* ' + wishObj.taking + ' is TAKING * : ' else ''
    return takingMsg + wishObj.runningNo + ']: ' + wishObj.msg + (if wishObj.createdBy then ' #' + wishObj.createdBy else '')

  handleRemove: (msg, id) ->
    wishList = @listing()
    success = @removeElement(id)
    if success.length > 0
      msg.send 'Wish removed -> ' + success[0].msg + (if success[0].createdBy then ' #' + success[0].createdBy else '')

  handleTake: (msg, id, userName) ->
    wishList = @listing()
    for key of wishList
      if (wishList[key].runningNo is parseInt(id, 10) )
        wishObj = wishList[key]
        oldTaking = wishObj.taking
        if oldTaking
          msg.send 'About to take taken wish, was #' + oldTaking
        wishObj.taking = userName
        @handleDisplayWish(wishObj, msg)

  findWishById: (id) ->
    wishList = @listing()
    for key of wishList
      if (wishList[key].runningNo is id )
        wishObj = wishList[key]
        return wishObj
    return null

  handleUnTake: (msg, id) ->
    wishObj = @findWishById(id)
    if wishObj
      if wishObj.taking
        wishObj.taking = null
        msg.send 'Untaking, ' + @formatWish(wishObj)

  handleAdd: (msg, wishMsg, userName) ->
    wish = new Reminder(wishMsg, userName)
    runNo = @add(wish)
    msg.send "Added, id = " + runNo


class Reminder
  constructor: (msg, createdBy) ->
    @msg = msg
    @createdBy = createdBy
    now = new Date
    @createdTime = now.toISOString()
    #@taking
  
module.exports = (robot) ->

  reminders = new Reminders robot

  robot.respond /wa (.*)/i, (msg) ->
    wishMsg = msg.match[1].trim()
    reminders.handleAdd(msg, wishMsg, msg.message.user.name)

  robot.hear /^-wa (.*)/i, (msg) ->
    wishMsg = msg.match[1].trim()
    reminders.handleAdd(msg, wishMsg, msg.message.user.name)

  robot.respond /wl/i, (msg) ->
    reminders.handleListing(msg)

  robot.hear /^-wl/i, (msg) ->
    reminders.handleListing(msg)

  robot.respond /wr (.*)/i, (msg) ->
    id = msg.match[1].trim()
    reminders.handleRemove(msg, id)

  robot.hear /^-wr (.*)/i, (msg) ->
    id = msg.match[1].trim()
    reminders.handleRemove(msg, id)

  robot.respond /wt (.*)/i, (msg) ->
    id = parseInt(msg.match[1].trim(), 10)
    reminders.handleTake(msg, id, msg.message.user.name)

  robot.hear /^-wt (.*)/i, (msg) ->
    id = parseInt(msg.match[1].trim(), 10)
    reminders.handleTake(msg, id, msg.message.user.name)

  robot.respond /wu (.*)/i, (msg) ->
    id = parseInt(msg.match[1].trim(), 10)
    reminders.handleUnTake(msg, id)

  robot.hear /^-wu (.*)/i, (msg) ->
    id = parseInt(msg.match[1].trim(), 10)
    reminders.handleUnTake(msg, id)

