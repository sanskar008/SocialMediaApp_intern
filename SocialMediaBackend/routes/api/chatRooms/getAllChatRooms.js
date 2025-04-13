const { chatRooms: chatRoomsMongo , chatMessages : chatMessagesMongo  , messageInteractions : messageInteractionsMongo} = require('../../../db/mongo');
const { parseParticipants } = require("./participantPaser");

const getAllChatRooms = {};

getAllChatRooms.fetchChatRooms = async (req, res, next) => {
  const userId = req.userId;

  try {
    let chatRooms = await chatRoomsMongo.instance.getAllChatRooms(userId);

    chatRooms = await Promise.all(chatRooms.map(parseParticipants));
    
    req.chatRooms = chatRooms;
    
    chatRooms = await Promise.all(chatRooms.map(async (chatRoom) => {
      const messages = await chatMessagesMongo.instance.getLast10Messages(chatRoom.chatRoomId);
      const unseenCount = await messageInteractionsMongo.instance.getUnseenCountForMessages(messages, userId);
      return { ...chatRoom, unseenCount };
    }));


    next();
  } catch (err) {
    console.error("Error fetching chat rooms:", err.message);
    next({ status: 500, message: "Internal Server Error" });
  }
};

getAllChatRooms.fetchUnseenCounts = async (req, res, next) => {
  const userId = req.userId;
  let chatRooms = req.chatRooms;
  try {
    
    chatRooms = await Promise.all(chatRooms.map(async (chatRoom) => {
      const messages = await chatMessagesMongo.instance.getLast10Messages(chatRoom.chatRoomId);
      const unseenCount = await messageInteractionsMongo.instance.getUnseenCountForMessages(messages, userId);
      return { ...chatRoom, unseenCount };
    }));

    req.chatRooms = chatRooms;

    next();
  } catch (err) {
    console.error("Error fetching chat rooms:", err.message);
    next({ status: 500, message: "Internal Server Error" });
  }
};

getAllChatRooms.prepareDMBlockFilter = (req, res, next) => {
  try {
    const { chatRooms } = req;
    const dmParticipantIds = [];

    chatRooms.forEach(room => {
      if (room.roomType === 'dm') {
        room.participants.forEach(participant => {
          if (participant && !dmParticipantIds.includes(participant.userId)) {
            dmParticipantIds.push(participant.userId);
          }
        });
      }
    });
    req._toBeFiltered = dmParticipantIds;
    next();
  } catch (err) {
    console.error("Error in prepareDMBlockFilter:", err.message);
    next({ status: 500, message: "Internal Server Error" });
  }
};

getAllChatRooms.applyDMBlockFilter = (req, res, next) => {
  try {
    const allowedIds = req.filteredAfterBlockCheckUserIds || [];
    req.chatRooms = req.chatRooms.filter(room => {
      if (room.roomType === 'dm') {
        const filteredParticipants = room.participants.filter(participant =>
          participant && allowedIds.includes(participant.userId)
        );
        if (filteredParticipants.length === 0) {
          return false;
        } else {
          room.participants = filteredParticipants;
          return true;
        }
      }
      return true;
    });
    next();
  } catch (err) {
    console.error("Error applying DM block filter:", err.message);
    next({ status: 500, message: "Internal Server Error" });
  }
};


getAllChatRooms.buildResponse = (req, res) => {
  return res.status(200).json({
    message: "Chat rooms fetched successfully.",
    chatRooms: req.chatRooms,
  });
};

module.exports = getAllChatRooms;
