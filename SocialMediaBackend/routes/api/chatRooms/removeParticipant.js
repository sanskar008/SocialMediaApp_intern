const { chatRooms: chatRoomsMongo } = require("../../../db/mongo");
const { FIELDS: CHAT_ROOM_FIELDS } = require("../../../db/mongo/chatRooms");
const { parseParticipants } = require("./participantPaser");

const removeParticipant = {};

// Middleware to validate request body
removeParticipant.validateRequestBody = (req, res, next) => {
  const { chatRoomId, participant } = req.body;

  if (!chatRoomId) {
    return res.status(400).json({ message: "`chatRoomId` is required." });
  }

  if (!participant) {
    return res.status(400).json({ message: "`participant` is required." });
  }

  req.chatRoomId = chatRoomId;
  req.participant = participant;
  next();
};

removeParticipant.checkAdminPrivileges = async (req, res, next) => {
  const { chatRoomId } = req;
  const userId = req.userId;

  try {
    const chatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    if (!chatRoom) {
      return res.status(404).json({ message: "Chat room not found." });
    }
    
    if (chatRoom[CHAT_ROOM_FIELDS.ADMIN] !== userId) {
      return res.status(403).json({ message: "You do not have permission to remove participants from this group." });
    }

    req.chatRoom = chatRoom;
    next();
  } catch (err) {
    next({ status: 500, message: "Internal Server Error" });
  }
};

// Handler to remove participant
removeParticipant.removeParticipantFromGroup = async (req, res, next) => {
  const { chatRoomId, participant } = req;

  try {
    const updateResult = await chatRoomsMongo.instance.removeParticipants(chatRoomId, [participant]);

    if (!updateResult.matchedCount) {
      return res.status(404).json({ message: "Chat room not found or participant not part of the group." });
    }

    let updatedChatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    updatedChatRoom = await parseParticipants(updatedChatRoom);

    return res.status(200).json({
      message: "Participant removed successfully.",
      chatRoom: updatedChatRoom,
    });
  } catch (err) {
    next({ status: 500, message: "Internal Server Error" });
  }
};

module.exports = removeParticipant;
