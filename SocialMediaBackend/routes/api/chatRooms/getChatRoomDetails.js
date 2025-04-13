const { chatRooms: chatRoomsMongo, chatMessages: chatMessagesMongo, messageInteractions: messageInteractionsMongo } = require('../../../db/mongo');
const { parseParticipants } = require('./participantPaser');
const moment = require('moment');

const getChatRoomDetails = {};

/**
 * Validate the request to ensure a chatRoomId is provided.
 * Expects: chatRoomId in req.query.
 */
getChatRoomDetails.validateRequest = (req, res, next) => {
  const { chatRoomId } = req.query;
  if (!chatRoomId) {
    return res.status(400).json({ message: 'chatRoomId is required.' });
  }
  req.chatRoomId = chatRoomId;
  next();
};

/**
 * Fetch the chat room document using the provided chatRoomId.
 */
getChatRoomDetails.fetchChatRoom = async (req, res, next) => {
  const { chatRoomId } = req;
  try {
    const chatRoom = await chatRoomsMongo.instance.getChatRoomByChatRoomId(chatRoomId);
    if (!chatRoom) {
      return res.status(404).json({ message: 'Chat room not found.' });
    }
    req.chatRoom = chatRoom;
    next();
  } catch (err) {
    console.error("Error fetching chat room:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

/**
 * Parse participants using the shared parser.
 */
getChatRoomDetails.parseParticipants = async (req, res, next) => {
  try {
    // parseParticipants might modify the participants array (e.g., formatting)
    const parsedChatRoom = await parseParticipants(req.chatRoom);
    req.chatRoom = parsedChatRoom;
    next();
  } catch (err) {
    console.error("Error parsing chat room participants:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

/**
 * For DM chat rooms, extract the participant's user IDs and assign them to req._toBeFiltered.
 * (Assumes that in DM rooms the participant list contains only the other user.)
 */
getChatRoomDetails.prepareDMBlockFilter = (req, res, next) => {
  try {
    const { chatRoom } = req;
    if (chatRoom.roomType === 'group' || chatRoom.roomType == "dm") {
      const dmParticipantIds = [];
      chatRoom.participants.forEach(participant => {
        if (!dmParticipantIds.includes(participant.userId)) {
          dmParticipantIds.push(participant.userId);
        }
      });
      req._toBeFiltered = dmParticipantIds;
    }
    next();
  } catch (err) {
    console.error("Error in prepareDMBlockFilter:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

/**
 * Apply DM block filtering.
 * Expects that blockService.filterBlockIdsMiddleware has run and set req.filteredAfterBlockCheckUserIds.
 * If the allowed list does not include the DM participant, return a 403 response.
 */
getChatRoomDetails.applyDMBlockFilter = (req, res, next) => {
  try {
    if (req.chatRoom.roomType === 'group' || req.chatRoom.roomType == "dm") {
      const allowedIds = req.filteredAfterBlockCheckUserIds || [];
      const filteredParticipants = req.chatRoom.participants.filter(participant =>
        allowedIds.includes(participant.userId)
      );
      if (filteredParticipants.length === 0) {
        return res.status(403).json({ message: "You are blocked from this chat room." });
      }
      req.chatRoom.participants = filteredParticipants;
    }
    next();
  } catch (err) {
    console.error("Error applying DM block filter:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

/**
 * Filter participants to allow only those with an "active" status.
 */
getChatRoomDetails.filterActiveParticipants = (req, res, next) => {
  try {
    req.chatRoom.participants = req.chatRoom.participants.filter(participant => participant.status === 'active');
    next();
  } catch (err) {
    console.error("Error filtering active participants:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};


/**
 * Build and send the response with chat room details.
 */
getChatRoomDetails.buildResponse = (req, res) => {
  res.status(200).json({
    message: "Chat room details fetched successfully.",
    chatRoom: req.chatRoom
  });
};

module.exports = getChatRoomDetails;