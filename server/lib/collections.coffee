@ChatMessage = new Meteor.Collection 'rocketchat_message'
@ChatRoom = new Meteor.Collection 'rocketchat_room'
@ChatSubscription = new Meteor.Collection 'rocketchat_subscription'
@MapReducedStatistics = new Mongo.Collection 'rocketchat_mr_statistics'
@ChatReports = new Meteor.Collection 'rocketchat_reports'
