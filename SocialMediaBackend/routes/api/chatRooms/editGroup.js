const { chatRooms: chatRoomsMongo } = require("../../../db/mongo");
const { FIELDS: CHAT_ROOM_FIELDS } = require("../../../db/mongo/chatRooms");
const { parseParticipants } = require("./participantPaser");

const EDIT_GROUP_FIELDS = {
  CHAT_ROOM_ID: "chatRoomId",
  GROUP_NAME: "groupName",
  BIO: "bio",
  IMAGE: "image",
};

const editGroup = {};

editGroup.validateRequestBody = (req, res, next) => {
  const updates = req.body;
  if (!updates || Object.keys(updates).length === 0) {
    return res.status(400).json({ message: "Request body cannot be empty. Please provide fields to update." });
  }
  const validFields = Object.values(EDIT_GROUP_FIELDS);
  const invalidFields = Object.keys(updates).filter((field) => !validFields.includes(field));
  if (invalidFields.length > 0) {
    return res.status(400).json({ message: `Invalid fields provided: ${invalidFields.join(", ")}` });
  }
  req.body.entityType = 'group';
  req.updates = updates;
  next();
};

editGroup.checkAdminPrivileges = async (req, res, next) => {
  const { chatRoomId } = req.body;
  const userId = req.userId;
  try {
    const chatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    if (!chatRoom) {
      return res.status(404).json({ message: "Chat room not found." });
    }
    if (chatRoom[CHAT_ROOM_FIELDS.ADMIN] !== userId) {
      return res.status(403).json({ message: "You do not have permission to edit this group." });
    }
    next();
  } catch (err) {
    next({ status: 500, message: "Internal Server Error" });
  }
};

editGroup.updateGroupProfile = async (req, res, next) => {
  const { chatRoomId } = req.body;
  const updates = req.updates;
  try {
    if (req.files && req.files.image) {
      updates[CHAT_ROOM_FIELDS.PROFILE_URL] = req?._media[0]?.url;
    }
    const updateResult = await chatRoomsMongo.instance.updateGroupProfile(chatRoomId, updates);
    if (!updateResult.modifiedCount) {
      return res.status(404).json({ message: "Group not found or no changes were made." });
    }
    let updatedChatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    updatedChatRoom = await parseParticipants(updatedChatRoom);
    return res.status(200).json({
      message: "Group profile updated successfully.",
      chatRoom: updatedChatRoom,
    });
  } catch (err) {
    next({ status: 500, message: "Internal Server Error" });
  }
};

module.exports = editGroup;
