Meteor.methods
	addUserToRoom: (data) ->
		fromId = Meteor.userId()
		# console.log '[methods] addUserToRoom -> '.green, 'fromId:', fromId, 'data:', data

		room = ChatRoom.findOne data.rid

		# if room.username isnt Meteor.user().username and room.t is 'c'
		if room.t is 'c' and room.u?.username isnt Meteor.user().username
			throw new Meteor.Error 403, '[methods] addUserToRoom -> Not allowed'

		# verify if user is already in room
		if room.usernames.indexOf(data.username) isnt -1
			return

		now = new Date()

		update =
			$addToSet:
				usernames: data.username

		newUser = RocketChat.models.Users.findOneByUsername username: data.username

		ChatRoom.update data.rid, update

		RocketChat.models.Subscriptions.createWithRoomAndUser room, newUser,
			ts: now
			open: true
			alert: true
			unread: 1

		ChatMessage.insert
			rid: data.rid
			ts: now
			t: 'au'
			msg: newUser.name
			u:
				_id: fromId
				username: Meteor.user().username

		return true
