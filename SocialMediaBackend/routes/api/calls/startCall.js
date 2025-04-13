const callService = require('./service');
const { calls: callsMongo , users : usersMongo , chatRooms : chatRoomsMongo } = require("../../../db/mongo");
const { callNotif } = require('../../messages');
const { v4: uuidv4 } = require("uuid");


const startCall = {};

startCall.validateBody = (req, res, next) => {
    const from = req.userId;
    const { to, type } = req.body; //to is now chatRoomId

    try {

        if (!from || !to || !type) {
            return res.status(400).json({ message: 'Caller, chatRoom, and call type are required.' });
        }

        next();
    } catch (error) {
        console.error('Validation Error:', error.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

/*startCall.checkCallStatus = async (req, res, next) => {
    const from = req.userId;

    try {

        const ongoingCall = await callsMongo.instance.getOngoingCalls(from);
        if (ongoingCall.length) {
            return res.status(200).json({ message: 'You already have an ongoing call.' });
        }

        next();
    } catch (error) {
        console.error('Check Call Status Error:', error.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};*/

startCall.checkCallStatus = async (req, res, next) => {
    const from = req.userId;
  
    try {
      const ongoingCalls = await callsMongo.instance.getOngoingCalls(from);
      if (ongoingCalls.length) {
        for (const call of ongoingCalls) {
          await callsMongo.instance.endCall(call._id);
        }
      }
      next();
    } catch (error) {
      console.error('Check Call Status Error:', error.message);
      return res.status(500).json({ message: 'Internal Server Error' });
    }
};
  

startCall.fetchParticipants = async (req, res, next) => {
    const { to : chatRoomId } = req.body;

    try {
        const chatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);

        if (!chatRoom) {
            return res.status(404).json({ message: 'Chat room not found.' });
        }
        
        if (chatRoom.roomType === "dm") {
            req.body.participants = chatRoom.participants;
        } else if (chatRoom.roomType === "group") {
            req.body.participants = chatRoom.participants.map(participant => participant.userId);
        }

        next();
    } catch (error) {
        console.error('Error fetching participants:', error);
        return res.status(500).json({ message: 'Internal Server Error while fetching participants' });
    }
};

startCall.generateChannelName = (req, res, next) => {
    const from = req.userId;

    try {
        const channelName = uuidv4();
        req.channelName = channelName;

        next();
    } catch (error) {
        console.error('Channel Name Generation Error:', error.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

startCall.initiateCall = async (req, res, next) => {
    const from = req.userId;
    const { participants, type , to } = req.body;
    const { channelName } = req;

    try {
        const token = await callService.generateAgoraToken(channelName, from);
        const callData = await callsMongo.instance.createCall({ from, participants, channelName, type , chatRoomId : to });

        req.callData = callData;
        req.token = token;

        next();
    } catch (error) {
        console.error('Initiate Call Error:', error.message);
        return res.status(500).json({ message: 'Failed to initiate call.' });
    }
};

startCall.notifyUsers = async (req, res) => {
    const token = req.token;
    const callData = req.callData;


    const { to } = req.body;

    try {
        // callNotif.send({from : req.userId, to :to , callId : callData?._id })
        
        return res.status(200).json({
            message: 'Call initiated successfully.',
            call: callData,
            token,
        });
    } catch (error) {
        console.error('Push Notification Error: ', error.message);
        return res.status(500).json({ message: 'Failed to initiate call.' });
    }

};

module.exports = startCall;
