const { users: usersMongo } = require('../../db/mongo');
const async = require("async");
const moment = require("moment");
const { calls: callsMongo, chatRooms : chatRoomsMongo } = require("../../db/mongo");
const { users: userRedis } = require('../../db/redis');
const sendPushNotification = require('../../services/firebase/sender');

const callNotif = {};

callNotif.send = async (data) => {
    const { userId, callId, type } = data;

    const fromDetails = await usersMongo.instance.getUserDetailsFromId(userId);
    const call = await callsMongo.instance.getCallById(callId);
    const chatRoomInfo = await chatRoomsMongo.instance.getChatRoomInfo(callId?.to);

    const message = `Incoming ${type} call from ${fromDetails.name}`;
    const senderInfo = fromDetails;

    // Collect all participant userIds
    const participantUserIds = call.participants.map(participant => participant.userId);

    // Fetch user details in bulk
    const userDetailsList = await usersMongo.instance.getUserDetailsFromIds(participantUserIds);

    const tokens = [];

    // Iterate over fetched user details
    for (const userDetails of userDetailsList) {
        if (userDetails?.fcmToken && userDetails._id !== senderInfo._id) {
            tokens.push(userDetails.fcmToken);
        }
    }

    // Send push notification for all participants at once
    if (tokens.length > 0) {
        await sendPushNotification({
            dataPayload: {
                title: `Incoming ${type} Call`,
                body: message,
            },
            tokens: tokens,
            payload: {
                type: "call",
                callId: callId,
                callType: type,
                senderId: userId,
                senderInfo: senderInfo,
                notificationImage: chatRoomInfo?.roomType === 'dm' ? senderInfo.profilePic : chatRoomInfo?.roomProfileUrl,
            },
        });
    }
};

module.exports = callNotif;