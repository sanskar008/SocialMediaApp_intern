const NotificationSaver = require("./notificationSaver");
const { users: usersMongo, feeds: feedsMongo, comments: commentsMongo } = require("../../db/mongo");
const sendPushNotification = require('../../services/firebase/sender');
const { users : userRedis } = require('../../db/redis');

const reaction = {};

reaction.send = async ({ senderId, receiverId, entityId, entityType , reactionId , post}) => {
  try {
    if (senderId === receiverId) return;

    let sender = await usersMongo.instance.getUserShowingDetails([senderId]);
    sender = sender[0];

    // Determine notification details based on entity type
    let notificationText, notificationImage, content = null;

    if (entityType === "feed") {
      notificationImage = sender.profilePic;
      notificationText = `${sender.name} reacted on your post.`;
    } 
    else if (entityType === "comment") {
      const comment = await commentsMongo.instance.findComment(entityId);
      if (!comment) return;

      notificationImage = sender.profilePic;
      notificationText = `${sender.name} reacted on your comment.`;
      content = comment.comment; // Add comment text as content
    }

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
      type: "reaction",
      senderId,
      senderInfo: sender,
      notificationImage,
      details: {
        notificationText,
      },
    }
    sendPushNotification({dataPayload, tokens, payload} )

    // Save the notification
    await NotificationSaver.saveNotification({
      type: "like",
      sender: { id: senderId, name: sender.name, profilePic: sender.profilePic },
      receiverId,
      details: {
        entityType,
        entityId,
        notificationImage,
        notificationText,
        content,
        entity : post,
        headerId: reactionId,
      },
    });
  } catch (err) {
    console.error("❌ Error processing like notification:", err.message);
  }
};

module.exports = reaction;
