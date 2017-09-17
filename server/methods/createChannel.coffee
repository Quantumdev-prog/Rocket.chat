Meteor.methods
	createChannel: (name, members) ->
		if not Meteor.userId()
			throw new Meteor.Error 'invalid-user', "[methods] createChannel -> Invalid user"

		if not /^[0-9a-z-_]+$/.test name
			throw new Meteor.Error 'name-invalid'

		if RocketChat.authz.hasPermission(Meteor.userId(), 'create-c') isnt true
			throw new Meteor.Error 'not-authorized', '[methods] createChannel -> Not authorized'

		console.log '[methods] createChannel -> '.green, 'userId:', Meteor.userId(), 'arguments:', arguments

		now = new Date()
		user = Meteor.user()

		members.push user.username

		# avoid duplicate names
		if RocketChat.models.Rooms.findOneByName name
			throw new Meteor.Error 'duplicate-name'

		# name = s.slugify name

		room =
			usernames: members
			ts: now
			t: 'c'
			name: name
			msgs: 0
			u:
				_id: Meteor.userId()
				username: user.username

		RocketChat.callbacks.run 'beforeCreateChannel', user, room

		# create new room
		room._id = ChatRoom.insert room
		# set creator as channel moderator.  permission limited to channel by scoping to rid
		RocketChat.authz.addUsersToRoles(Meteor.userId(), 'moderator', room._id)

		for username in members
			member = RocketChat.models.Users.findOneByUsername username
			if not member?
				continue

			extra = {}

			if username is user.username
				extra.ls = now
				extra.open = true

			RocketChat.models.Subscriptions.createWithRoomAndUser room, member, extra

		Meteor.defer ->
			RocketChat.callbacks.run 'afterCreateChannel', user, room

		return {
			rid: room._id
		}
