const moment = require('moment');
const { instance: ChatMessages  } = require("../../../db/mongo/chatMessages");
const { chatRooms : chatRoomsMongo} = require('../../../db/mongo')

const getAllMessages = {};

getAllMessages.validateRequest = async(req, res, next) => {
  try {
    const { roomId, page, limit } = req.body;

    if (!roomId) {
      return res.status(400).json({ message: "Room ID is required." });
    }

    const bool = await chatRoomsMongo.instance.getChatRoomByChatRoomId(roomId);

    if(bool){
      req._botRoom = bool.isBot || false
    }
    else{
      return res.status(500).json({ message: "Internal Server Error" });
    }

    req.body.page = parseInt(page) > 0 ? parseInt(page) : 1;
    req.body.limit = parseInt(limit) > 0 ? parseInt(limit) : 20;

    next();
  } catch (error) {
    console.error("Validation Error:", error.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

getAllMessages.fetchMessages = async (req, res) => {
  try {
    const { roomId, page, limit } = req.body;

    const { messages, totalMessages, totalPages } = await ChatMessages.getMessagesByRoomId(roomId, page, limit, req?._botRoom);

    const updatedMessages = messages.map((message) => ({
        ...message,
        date: moment(message.createdAt).format('DD/MM/YYYY'),
        time: moment(message.createdAt).format('HH:mm'),
        agoTime: moment(message.createdAt).fromNow(),
    }));

    return res.status(200).json({
      message: "Messages fetched successfully",
      totalMessages,
      totalPages,
      currentPage: page,
      messages: updatedMessages,
    });
  } catch (error) {
    console.error("Fetch Messages Error:", error.message);
    return res.status(500).json({ message: "Failed to fetch messages." });
  }
};

module.exports = getAllMessages;
