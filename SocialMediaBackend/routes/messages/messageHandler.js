const {chatMessages :  messagesMongo, chatRooms : chatRoomsMongo } = require('../../db/mongo')
const { socketData : socketDataRedis } = require('../../db/redis') 
const async = require('async');
const { users : userRedis } = require('../../db/redis');
const sendPushNotification = require('../../services/firebase/sender');
const moment = require('moment')

const messageHandler = {};

messageHandler.checkAuthorization = async(senderId, entityId) => {
    const authorized = await chatRoomsMongo.instance.checkUserExistenceInRoom(senderId, entityId);
    if(!authorized) return false;
    return true;
}

messageHandler.createMessage = async(data) => {
    const { senderId , content , entityId , media, entity } = data;

    const createMessage = await messagesMongo.instance.createMessage(content, senderId , entityId, media, entity);
    await chatRoomsMongo.instance.updateLastMessage(entityId,createMessage._id , moment().unix(), content)

    return createMessage;
}


messageHandler.sendNotificationsToOffline = async(entityId, content, senderId) => {
    try {
        let senderInfo = await userRedis.getUserDetails(senderId);
        senderInfo = JSON.parse(senderInfo);
        const chatRoomInfo = await chatRoomsMongo.instance.getChatRoomInfo(entityId);
        const online = await socketDataRedis.getRoomParticipants(entityId);
        console.log(online)
        let userInRoom = chatRoomInfo.participants
        const offlineUsers = userInRoom.filter(user => !online.includes(user) && user !== senderId);
        const tokens = [];

        await async.parallelLimit(
            offlineUsers.map(userId => async () => {
            try {
                const userDetails = await userRedis.getUserDetails(userId);
                const parsedDetails = JSON.parse(userDetails);
                if (parsedDetails?.fcmToken) {
                tokens.push(parsedDetails.fcmToken);
                }
            } catch (err) {
                console.error(`Error fetching details for user ${userId}:`, err);
            }
            }),
            10  // -----> This ensures 10 scripts only at once 
        );

        let title = chatRoomInfo.roomType == 'dm' ? senderInfo.name : chatRoomInfo.groupName
        
        await sendPushNotification({dataPayload : { title, body: content}, tokens :tokens , payload : {
            type:"message",
            senderId : senderId,
            senderInfo: senderInfo,
            notificationImage:chatRoomInfo.roomType == 'dm' ? senderInfo.profilePic : chatRoomInfo.profileUrl, 
            details : {notificationText: content},
        } })
        
    } catch (error) {
        console.error('Error in sendNotificationsToOffline:', error);
    }
};

module.exports = messageHandler