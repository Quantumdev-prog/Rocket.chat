Meteor.methods
	saveUserPreferences: (settings) ->
		console.log '[method] saveUserPreferences', settings

		if Meteor.userId()
			preferences = {}

			if settings.disableNewRoomNotification?
				preferences.disableNewRoomNotification = if settings.disableNewRoomNotification is "1" then true else false

			if settings.disableNewMessageNotification?
				preferences.disableNewMessageNotification = if settings.disableNewMessageNotification is "1" then true else false
			
			Meteor.users.update Meteor.userId(), { $set: { "settings.preferences": preferences } }

			return true
