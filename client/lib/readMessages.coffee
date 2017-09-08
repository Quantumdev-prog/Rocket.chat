### DEFINITIONS
- If window loses focus user needs to scroll or click/touch some place
- On hit ESC enable read, force read of current room and remove unread mark
- When user change room disable read until user interaction
- Only read if mark of *first-unread* is visible for user or if flag *force* was passed
- Always read the opened room
- The default method *read* has a delay of 2000ms to prevent multiple reads and to user be able to see the mark
###

Meteor.startup ->
	window.addEventListener 'focus', ->
		readMessage.refreshUnreadMark()

@readMessage = new class
	constructor: ->
		@canReadMessage = false

	readNow: (force=false) ->
		self = @
		return if force isnt true and @canReadMessage is false

		rid = Session.get 'openedRoom'
		if not rid?
			return

		if force is true
			return Meteor.call 'readMessages', rid, ->
				self.refreshUnreadMark()

		subscription = ChatSubscription.findOne rid: rid
		if not subscription? or (subscription.alert is false and subscription.unread is 0)
			return

		room = RoomManager.openedRooms[subscription.t + subscription.name]
		if not room?
			return

		# Only read messages if user saw the first unread message
		position = $('.message.first-unread').position()
		if position? and position.top >= 0
			Meteor.call 'readMessages', rid, ->
				self.refreshUnreadMark()

	read: _.debounce (force) ->
		@readNow(force)
	, 1000

	disable: ->
		@canReadMessage = false

	enable: ->
		@canReadMessage = document.hasFocus()

	isEnable: ->
		return @canReadMessage is true

	refreshUnreadMark: (rid) ->
		self = @
		@disable()
		rid ?= Session.get 'openedRoom'
		if not rid?
			return @enable()

		subscription = ChatSubscription.findOne rid: rid
		if not subscription?
			return @enable()

		room = RoomManager.openedRooms[subscription.t + subscription.name]
		if not room?
			return @enable()

		room.loadingUnread = true

		$roomDom = $(room.dom)
		$roomDom.find('.message.first-unread').addClass('first-unread-opaque')

		# if (subscription.rid isnt rid or readMessage.isEnable() is false)

		if not subscription.alert and subscription.unread is 0
			room.unreadLoading = false
			room.unreadCount.set 0
			return @enable()

		$roomDom.find('.message.first-unread').removeClass('first-unread').removeClass('first-unread-opaque')
		Meteor.call 'countAndFirstId', subscription.rid, (error, data) ->
			room.unreadLoading = false
			room.unreadCount.set data.count
			room.unreadSince.set data.since
			room.unreadFirstId = data.firstUnreadId

			self.enable()
			console.log arguments
			# firstUnreadId = ChatMessage.findOne({rid: subscription.rid, ts: {$gt: subscription.ls}, 'u._id': {$ne: Meteor.userId()}}, {sort: {ts: 1}})?._id
			if data.firstUnreadId?
				$roomDom.find('.message#'+data.firstUnreadId).addClass('first-unread')


Meteor.startup ->
	$(window).on 'blur', ->
		readMessage.disable()

	$(window).on 'focus', ->
		readMessage.enable()
		readMessage.read()

	$(window).on 'click', (e) ->
		readMessage.enable()
		readMessage.read()

	$(window).on 'touchend', (e) ->
		readMessage.enable()
		readMessage.read()

	$(window).on 'keyup', (e) ->
		key = e.which

		if key is 27
			readMessage.enable()
			readMessage.readNow(true)
			$('.message.first-unread').removeClass('first-unread')
