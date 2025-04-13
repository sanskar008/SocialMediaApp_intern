const NotificationSaver = require("./notificationSaver");
const { users: usersMongo, feeds: feedsMongo } = require("../../db/mongo");
const { users : userRedis } = require('../../db/redis');
const sendPushNotification = require('../../services/firebase/sender');

const commentNotification = {};

commentNotification.send = async ({ senderId, post, commentText , commentId }) => {
  try {
    let sender = await usersMongo.instance.getUserShowingDetails([senderId]);
    sender = sender[0];

    const receiverId = post.author;

    // Avoid sending notification to self
    if (senderId === receiverId) return;

    // Build notification details
    const notificationImage = sender.profilePic;
    const notificationText = `${sender.name} commented on your post.`;

    const tokens = [];

    
    let userDetails = await userRedis.getUserDetails(post.author);
    const parsedDetails = JSON.parse(userDetails);
    userDetails = parsedDetails;
    if (parsedDetails?.fcmToken) {
    tokens.push(parsedDetails.fcmToken);
    }
    const dataPayload = {
      title : `Hey ${userDetails.name}`,
      body: notificationText,
    }
    const payload = {
      type: "comment",
      senderId,
      senderInfo: sender,
      notificationImage,
      details: {
        notificationText,
      },
    }
    sendPushNotification({dataPayload, tokens, payload} )


    await NotificationSaver.saveNotification({
      type: "comment",
      sender: { id: senderId, name: sender.name, profilePic: sender.profilePic },
      receiverId,
      details: {
        entityType: "feed",
        entityId: post.feedId,
        notificationImage,
        notificationText,
        content: commentText,
        entity: post,
        headerId: commentId,
      },
    });
  } catch (err) {
    console.error("❌ Error processing comment notification:", err.message);
  }
};

module.exports = commentNotification;
