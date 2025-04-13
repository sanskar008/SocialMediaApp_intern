const { instance: MongoDBInstance } = require("./db");

const users = require('./users')
const feeds = require('./feeds')
const calls = require('./calls.js');
const stories = require('./stories');
const reactions = require('./reactions')
const chatRooms = require("./chatRooms");
const comments = require('./comments.js')
const followers = require('./followers.js')
const chatMessages = require("./chatMessages");
const liveStreams = require("./liveStreams.js");
const bannedUsers = require('./bannedUsers.js');
const blockedUsers = require("./blockedUsers.js");
const notifications = require("./notifications.js");
const recentSearches = require('./recentSearches.js');
const storiesInteraction = require("./storiesInteraction.js");
const messageInteractions = require('./messageInteraction.js');
const contentInteractions = require('./userContentInteractions.js');

const mongo = {};

mongo.initialize = async () => {
  await MongoDBInstance.connect();
  await users.instance.init();
  await feeds.instance.init();
  await calls.instance.init();
  await stories.instance.init();
  await comments.instance.init();
  await chatRooms.instance.init();
  await followers.instance.init();
  await reactions.instance.init();
  await liveStreams.instance.init();
  await bannedUsers.instance.init();
  await chatMessages.instance.init();
  await blockedUsers.instance.init();
  await notifications.instance.init();
  await recentSearches.instance.init();
  await storiesInteraction.instance.init();
  await messageInteractions.instance.init();
};

mongo.users = users;
mongo.feeds = feeds;
mongo.calls = calls;
mongo.stories = stories;
mongo.comments = comments;
mongo.reactions = reactions;
mongo.followers = followers;
mongo.chatRooms = chatRooms;
mongo.liveStreams = liveStreams;
mongo.bannedUsers = bannedUsers;
mongo.chatMessages = chatMessages;
mongo.blockedUsers = blockedUsers;
mongo.notifications = notifications;
mongo.recentSearches = recentSearches;
mongo.storiesInteraction = storiesInteraction;
mongo.messageInteractions = messageInteractions;

module.exports = mongo;