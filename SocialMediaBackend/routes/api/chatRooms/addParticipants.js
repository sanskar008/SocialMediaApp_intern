const { chatRooms: chatRoomsMongo } = require("../../../db/mongo");
const { FIELDS: CHAT_ROOM_FIELDS } = require("../../../db/mongo/chatRooms");
const { parseParticipants } = require("./participantPaser");

const addParticipant = {};

addParticipant.validateRequestBody = (req, res, next) => {
  const { chatRoomId, participants } = req.body;

  if (!chatRoomId) {
    return res.status(400).json({ message: "`chatRoomId` is required." });
  }

  if (!Array.isArray(participants) || participants.length === 0) {
    return res.status(400).json({ message: "`participants` must be a non-empty array." });
  }

  req.chatRoomId = chatRoomId;
  req.participants = participants;
  next();
};

addParticipant.checkAdminPrivileges = async (req, res, next) => {
  const { chatRoomId } = req;
  const userId = req.userId;

  try {
    const chatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    if (!chatRoom) {
      return res.status(404).json({ message: "Chat room not found." });
    }

    if (chatRoom[CHAT_ROOM_FIELDS.ADMIN] !== userId) {
      return res.status(403).json({ message: "You do not have permission to add participants to this group." });
    }

    req.chatRoom = chatRoom;
    next();
  } catch (err) {
    next({ status: 500, message: "Internal Server Error" });
  }
};

addParticipant.addParticipantsToGroup = async (req, res, next) => {
  const { chatRoomId, participants } = req;
  const { [CHAT_ROOM_FIELDS.PARTICIPANTS]: existingParticipants } = req.chatRoom;

  try {

    const newParticipants = participants.filter(
    (participantId) =>
    !existingParticipants.some(
      (existing) => existing.userId === participantId && existing.status === "active"
    )
);
    if (newParticipants.length === 0) {
      return res.status(400).json({ message: "All participants are already in the group." });
    }

    const updateResult = await chatRoomsMongo.instance.addParticipants(chatRoomId, newParticipants);

    if (!updateResult.modifiedCount) {
      return res.status(404).json({ message: "Failed to add participants to the group." });
    }

    let updatedChatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    updatedChatRoom = await parseParticipants(updatedChatRoom);
    return res.status(200).json({
      message: "Participants added successfully.",
      chatRoom: updatedChatRoom,
    });
  } catch (err) {
    next({ status: 500, message: "Internal Server Error" });
  }
};

module.exports = addParticipant;
