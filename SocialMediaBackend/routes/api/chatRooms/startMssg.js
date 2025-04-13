const { users : usersMongo , chatRooms : chatRoomsMongo } = require('../../../db/mongo');
const { parseParticipants } = require('./participantPaser');

const startMssg = {};

startMssg.validateRequest = (req, res, next) => {
  const userId1 = req.userId;
  const { userId2 } = req.body;

  if (!userId1 || !userId2) {
    return res.status(400).json({ error: "Both user IDs are required." });
  }
  next();
};

startMssg.checkExistingChatRoom = async (req, res, next) => {
  const userId1 = req.userId;
  const { userId2 } = req.body;
  try {
    let existingChatRoom = await chatRoomsMongo.instance.getChatDMRoomByParticipants([userId1, userId2]);
    if (existingChatRoom) {
      existingChatRoom = await parseParticipants(existingChatRoom);

    // Remove self user from participants before sending response
    existingChatRoom.participants = existingChatRoom.participants.filter(p => p.userId !== userId1);

      return res.status(200).json({ message: "Chat room already exists.", chatRoom: existingChatRoom });
    }
    next();
  } catch (err) {
    return res.status(500).json({ error: "Error checking existing chat room.", details: err.message });
  }
};

startMssg.createChatRoom = async (req, res) => {
  const userId1 = req.userId;
  const { userId2 } = req.body;
  try { 
    let botDetails = await usersMongo.instance.checkBot();
    let botId = botDetails._id;
    let isBot = null
    if(userId2 == botId){
      isBot = true
    }

    let chatRoom = await chatRoomsMongo.instance.createChatRoom([userId1, userId2], "dm",null,null,isBot);
    chatRoom = await parseParticipants(chatRoom);

    // Remove self user from participants before sending response
    chatRoom.participants = chatRoom.participants.filter(p => p.userId !== userId1);

    return res.status(201).json({ message: "Chat room created successfully.", chatRoom });
  } catch (err) {
    return res.status(500).json({ error: "Error creating chat room.", details: err.message });
  }
};

module.exports = startMssg;