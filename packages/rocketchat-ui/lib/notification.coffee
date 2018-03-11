# @TODO implementar 'clicar na notificacao' abre a janela do chat
@KonchatNotification =
	notificationStatus: new ReactiveVar

	# notificacoes HTML5
	getDesktopPermission: ->
		if window.Notification && Notification.permission != "granted"
			Notification.requestPermission (status) ->
				KonchatNotification.notificationStatus.set status
				if Notification.permission != status
					Notification.permission = status

	notify: (notification) ->
		if window.Notification && Notification.permission == "granted"
			message = { rid: notification.payload?.rid, msg: notification.text, notification: true }
			RocketChat.promises.run('onClientMessageReceived', message).then (message) ->
				n = new Notification notification.title,
					icon: notification.icon or getAvatarUrlFromUsername notification.payload.sender.username
					body: _.stripTags(message.msg)
					silent: true

				if notification.payload?.rid?
					n.onclick = ->
						window.focus()
						switch notification.payload.type
							when 'd'
								FlowRouter.go 'direct', {username: notification.payload.sender.username}
							when 'c'
								FlowRouter.go 'channel', {name: notification.payload.name}
							when 'p'
								FlowRouter.go 'group', {name: notification.payload.name}

	showDesktop: (notification) ->
		if not window.document.hasFocus?() and Meteor.user().status isnt 'busy'
			if Meteor.settings.public.sandstorm
				KonchatNotification.notify(notification)
			else
				getAvatarAsPng notification.payload.sender.username, (avatarAsPng) ->
					notification.icon = avatarAsPng
					KonchatNotification.notify(notification)

	newMessage: ->
		unless Session.equals('user_' + Meteor.userId() + '_status', 'busy') or Meteor.user()?.settings?.preferences?.disableNewMessageNotification
			$('#chatAudioNotification')[0].play()

	newRoom: (rid, withSound = true) ->
		Tracker.nonreactive ->
			newRoomSound = Session.get('newRoomSound')
			if newRoomSound?
				newRoomSound = _.union newRoomSound, rid
			else
				newRoomSound = [rid]

			Session.set('newRoomSound', newRoomSound)

		# $('.link-room-' + rid).addClass('new-room-highlight')

	removeRoomNotification: (rid) ->
		Tracker.nonreactive ->
			newRoomSound = Session.get('newRoomSound')
			newRoomSound = _.without newRoomSound, rid
			Session.set('newRoomSound', newRoomSound)

		$('.link-room-' + rid).removeClass('new-room-highlight')

Tracker.autorun ->
	if Session.get('newRoomSound')?.length > 0
		unless Session.equals('user_' + Meteor.userId() + '_status', 'busy') or Meteor.user()?.settings?.preferences?.disableNewRoomNotification
			$('#chatNewRoomNotification').each ->
				this.play()
	else
		$('#chatNewRoomNotification').each ->
			this.pause()
			this.currentTime = 0
