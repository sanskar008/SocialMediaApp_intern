const { chatRooms: chatRoomsMongo } = require("../../../db/mongo");

const leaveChatRoom = {};

/**
 * Validate that chatRoomId exists in the body
 */
leaveChatRoom.validateRequest = (req, res, next) => {
  const { chatRoomId } = req.body;
  if (!chatRoomId) {
    return res.status(400).json({ message: "chatRoomId is required." });
  }
  req.chatRoomId = chatRoomId;
  next();
};

/**
 * Fetch chatRoom & verify admin can't leave
 */
leaveChatRoom.verifyAdminLeave = async (req, res, next) => {
  const userId = req.userId;
  const chatRoomId = req.chatRoomId;

  try {
    const chatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);

    if (!chatRoom) {
      return res.status(404).json({ message: "Chat room not found." });
    }

    // Check if room is group and user is admin
    if (chatRoom.roomType === "group" && chatRoom.admin === userId) {
      return res.status(403).json({ message: "Admin cannot leave the group." });
    }

    next();
  } catch (err) {
    console.error("Error verifying admin leave:", err.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

/**
 * Update participant status to 'left'
 */
leaveChatRoom.leaveRoom = async (req, res) => {
  const userId = req.userId;
  const chatRoomId = req.chatRoomId;

  try {
    const result = await chatRoomsMongo.instance.leaveChatRoom(chatRoomId, userId);
    if (result.modifiedCount === 0) {
      return res.status(404).json({ message: "User not part of the chat room." });
    }

    res.status(200).json({ message: "Left the chat room successfully." });
  } catch (err) {
    console.error("Error leaving chat room:", err.message);
    res.status(500).json({ message: "Internal Server Error" });
  }
};

module.exports = leaveChatRoom;
