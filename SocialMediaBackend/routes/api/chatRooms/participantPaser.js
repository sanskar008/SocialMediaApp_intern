const { users: usersMongo } = require("../../../db/mongo");

/**
 * Parses participants for group chat rooms.
 *
 * @param {Object} chatRoom - The chat room object containing a participants array.
 * @returns {Promise<Object>} - The updated chat room object with detailed participant information.
 */
async function parseGroupParticipants(chatRoom) {
  try {
    if (!chatRoom || !Array.isArray(chatRoom.participants)) {
      throw new Error("Invalid chat room object or participants array.");
    }

    const participantIds = chatRoom.participants.map((participant) => String(participant.userId));
    const userDetails = await usersMongo.instance.getUserShowingDetails(participantIds);

    const updatedParticipants = chatRoom.participants.map((participant) => {
      const userDetail = userDetails.find((user) => String(user.userId) === String(participant.userId)) || {};
      return {
        ...participant,
        name: userDetail.name || null,
        profilePic: userDetail.profilePic || null,
      };
    });

    return {
      ...chatRoom,
      participants: updatedParticipants,
    };
  } catch (error) {
    console.error("Error parsing group participants:", error.message);
    throw error;
  }
}

/**
 * Parses participants for direct message (DM) chat rooms.
 *
 * @param {Object} chatRoom - The chat room object containing a participants array.
 * @returns {Promise<Object>} - The updated chat room object with detailed participant information.
 */
async function parseDMParticipants(chatRoom) {
  try {
    if (!chatRoom || !Array.isArray(chatRoom.participants)) {
      throw new Error("Invalid chat room object or participants array.");
    }
    
    const participantIds = chatRoom.participants;

    const userDetails = await usersMongo.instance.getUserShowingDetails(participantIds);

    const updatedChatRoom = {
      ...chatRoom,
      participants: userDetails,
    };

    return updatedChatRoom;
  } catch (error) {
    console.error("Error parsing participants:", error.message);
    throw error;
  }
}

module.exports = {
  parseParticipants,
};

/**
 * Main function to parse participants based on room type (dm or group).
 *
 * @param {Object} chatRoom - The chat room object containing a participants array.
 * @returns {Promise<Object>} - The updated chat room object with detailed participant information.
 */
async function parseParticipants(chatRoom) {
  try {
    if (!chatRoom || !chatRoom.roomType) {
      throw new Error("Invalid chat room object or missing roomType.");
    }

    if (chatRoom.roomType === "group") {
      return await parseGroupParticipants(chatRoom);
    } else if (chatRoom.roomType === "dm") {
      return await parseDMParticipants(chatRoom);
    } else {
      throw new Error("Unknown roomType. Expected 'group' or 'dm'.");
    }
  } catch (error) {
    console.error("Error parsing participants:", error.message);
    throw error;
  }
}

module.exports = {
  parseParticipants,
};
