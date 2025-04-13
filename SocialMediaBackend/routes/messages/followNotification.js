const { users : usersMongo } = require('../../db/mongo')
const async = require("async");
const moment = require("moment");
const { users : userRedis } = require('../../db/redis');
const sendPushNotification = require('../../services/firebase/sender');
const NotificationSaver = require('../notifications/notificationSaver');

const followNotification = {};

followNotification.send = async( senderId,receiverId) => {
    try {
       
        const tokens = [];
        let userDetails
        let senderInfo = await usersMongo.instance.getUserShowingDetails([senderId]);
        senderInfo = senderInfo[0];
        
            try {
                userDetails = await userRedis.getUserDetails(receiverId);
                const parsedDetails = JSON.parse(userDetails);
                userDetails = parsedDetails
                if (parsedDetails?.fcmToken) {
                tokens.push(parsedDetails.fcmToken);
                }
            } catch (err) {
                console.error(`Error fetching details for user ${userId}:`, err);
            }
            
        let title = `Hey ${userDetails.name}`
        let body = `${senderInfo.name} has sent you a follow request.`;


        await NotificationSaver.saveNotification({
              type: "followRequestSend",
              sender: { id: senderId, name: senderInfo.name, profilePic: senderInfo.profilePic },
              receiverId,
              details: {
                content:body
              },
            });
        
        await sendPushNotification({dataPayload : { title, body: body}, tokens :tokens , payload : {
            type:"followRequestSend",
            senderId : senderId,
            notificationImage:senderInfo.profilePic,
            details : {notificationText: body},
        } })
        
    } catch (error) {
        console.error('Error in sendNotificationsToOffline:', error);
    }
};

followNotification.accept = async(senderId, receiverId) => {
    try {
       
        const tokens = [];
        let userDetails
        let senderInfo = await userRedis.getUserDetails(senderId);
        senderInfo = JSON.parse(senderInfo);
        
            try {
                userDetails = await userRedis.getUserDetails(receiverId);
                const parsedDetails = JSON.parse(userDetails);
                userDetails = parsedDetails
                if (parsedDetails?.fcmToken) {
                tokens.push(parsedDetails.fcmToken);
                }
            } catch (err) {
                console.error(`Error fetching details`, err);
            }

            
        let title = `Hey ${userDetails.name}`
        let body = `${senderInfo.name} has accepted your follow request.`;

        await NotificationSaver.saveNotification({
            type: "followRequestAccept",
            sender: { id: senderId, name: senderInfo.name, profilePic: senderInfo.profilePic },
            receiverId,
            details: {
              content:body
            },
          });
        
        await sendPushNotification({dataPayload : { title, body: body}, tokens :tokens , payload : {
            type:"followRequestAccept",
            senderId : senderId,
            senderInfo: senderInfo,
            notificationImage:senderInfo.profilePic,
            details : {notificationText: body},
        } })
        
    } catch (error) {
        console.error('Error in sendNotificationsToOffline:', error);
    }
};

module.exports = followNotification