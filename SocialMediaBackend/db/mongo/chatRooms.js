const { MongoDB } = require("./db");
const { v4: uuidv4 } = require("uuid"); // Use UUID for generating chatRoomId
const collectionName = "chatRooms";

const FIELDS = {
  CHAT_ROOM_ID: "chatRoomId",
  PARTICIPANTS: "participants",
  ROOM_TYPE: "roomType", // "dm" or "group"
  LAST_MESSAGE: "lastMessage", // Reference to the latest message
  CREATED_AT: "createdAt",
  UPDATED_AT: "updatedAt",
  PROFILE_URL: "profileUrl", // New field for profile image URLs
  ADMIN: "admin", // Admin of the group
  GROUP_NAME: "groupName", // Group name field
  BIO:"bio",
  IS_BOT: "isBot"
};

class ChatRooms extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    const db = await super.getDBInstance();
    this.collection = db.collection(collectionName);
  }

  async createChatRoom(participants, roomType = "dm", admin = null, profileUrl = null,isBot = null) {
    const chatRoomId = uuidv4(); // Generate chatRoomId using UUID
    const chatRoom = {
      [FIELDS.CHAT_ROOM_ID]: chatRoomId,
      [FIELDS.PARTICIPANTS]: participants,
      [FIELDS.ROOM_TYPE]: roomType,
      [FIELDS.PROFILE_URL]: profileUrl, // Optional field for group profile
      [FIELDS.ADMIN]: admin, // Admin of the group
      [FIELDS.CREATED_AT]: new Date(),
      [FIELDS.UPDATED_AT]: new Date(),
      [FIELDS.IS_BOT] : isBot ?? false
    };
    
    const result = await this.collection.insertOne(chatRoom);

    // Fetch the inserted document
    if (result.insertedId) {
      const insertedChatRoom = await this.collection.findOne({ _id: result.insertedId });
      return insertedChatRoom; // Return the entire inserted document
    }

    throw new Error("Failed to create chat room");
  }

  async createChatGroupRoom(participants, admin, groupName, profileUrl = null) {
    if (!admin || !groupName) {
      throw new Error("Admin and groupName are required to create a group chat room");
    }
    const now = new Date();
    const formattedParticipants = participants.map((userId) => ({
      userId,
      status: "active",
      createdAt: now,
      updatedAt: now,
    }));
    
    const chatRoomId = uuidv4(); // Generate chatRoomId using UUID
    const chatRoom = {
      [FIELDS.CHAT_ROOM_ID]: chatRoomId,
      [FIELDS.PARTICIPANTS]: formattedParticipants,
      [FIELDS.ROOM_TYPE]: "group", // Set the room type to 'group'
      [FIELDS.GROUP_NAME]: groupName, // Add group name
      [FIELDS.PROFILE_URL]: profileUrl, // Optional field for group profile
      [FIELDS.ADMIN]: admin, // Set the admin
      [FIELDS.CREATED_AT]: new Date(),
      [FIELDS.UPDATED_AT]: new Date(),
      [FIELDS.IS_BOT]:false
    };

    const result = await this.collection.insertOne(chatRoom);

    if (result.insertedId) {
      const insertedChatRoom = await this.collection.findOne({ _id: result.insertedId });
      return insertedChatRoom; // Return the entire inserted document
    }

    throw new Error("Failed to create group chat room");
  }

  async getChatRoomInfo(chatRoomId) {
    try {
      const where = {
        [FIELDS.CHAT_ROOM_ID]: chatRoomId
      };
  
      // Use the promise-based version of findOne
      const data = await this.collection.findOne(where);
      return data // Resolve with the data
    } catch (err) {
      console.error("Error checking chatRoom Data", err); // Optional logging
      return err; // Re-throw the error for caller to handle
    }
  }
  
  async getChatRoomByChatRoomId(chatRoomId) {
    return this.collection.findOne({ [FIELDS.CHAT_ROOM_ID]: chatRoomId });
  }

  async getChatDMRoomByParticipants(participants) {
    return this.collection.findOne({
      [FIELDS.ROOM_TYPE]: "dm", // Ensure the room type is DM
      [FIELDS.PARTICIPANTS]: {
        $all: participants, // Match the array of strings directly
      },
    });
  }
  
  async updateLastMessage(chatRoomId, messageId, timestamp, content) {
    await this.collection.updateOne(
      { [FIELDS.CHAT_ROOM_ID]: chatRoomId },
      {
        $set: {
          [FIELDS.LAST_MESSAGE]: {
            messageId,
            timestamp,
            content,
          },
          [FIELDS.UPDATED_AT]: new Date(),
        },
      }
    );
  }

  async addParticipants(chatRoomId, participants) {
    const now = new Date();
    const formattedParticipants = participants.map((userId) => ({
      userId,
      status: "active",
      createdAt: now,
      updatedAt: now,
    }));
  
    const bulkOperations = [];
  
    for (const participant of formattedParticipants) {
      // Check if the participant is already in the group with a "removed" status
      bulkOperations.push({
        updateOne: {
          filter: {
            [FIELDS.CHAT_ROOM_ID]: chatRoomId,
            [FIELDS.PARTICIPANTS]: { $elemMatch: { userId: participant.userId, status: "removed" } },
          },
          update: {
            $set: { [`${FIELDS.PARTICIPANTS}.$.status`]: "active" },
          },
        },
      });
  
      // Add the participant if they are not in the group at all
      bulkOperations.push({
        updateOne: {
          filter: {
            [FIELDS.CHAT_ROOM_ID]: chatRoomId,
            [`${FIELDS.PARTICIPANTS}.userId`]: { $ne: participant.userId },
          },
          update: {
            $addToSet: { [FIELDS.PARTICIPANTS]: participant },
          },
        },
      });
    }
  
    // Execute all bulk operations
    const result = await this.collection.bulkWrite(bulkOperations);
    return result;
  }
  

  async removeParticipants(chatRoomId, participants) {
    return this.collection.updateMany(
      {
        [FIELDS.CHAT_ROOM_ID]: chatRoomId,
        [FIELDS.PARTICIPANTS + ".userId"]: { $in: participants },
      },
      {
        $set: {
          [`${FIELDS.PARTICIPANTS}.$.status`]: "removed",
          [FIELDS.UPDATED_AT]: new Date(),
        },
      }
    );
  }

  async getAllChatRooms(userId) {
    const chatRooms = await this.collection
      .find({
      $and: [
        {
        $or: [
          { [FIELDS.PARTICIPANTS]: userId }, // DM schema: array of userIds
          { [FIELDS.PARTICIPANTS]: { $elemMatch: { userId } } }, // Group schema: array of objects with userId
        ],
        },
        {
        $or: [
          { [FIELDS.IS_BOT]: { $exists: false } }, // isBot field does not exist
          { [FIELDS.IS_BOT]: false }, // isBot field is false
        ],
        },
      ],
      })
      .sort({ [FIELDS.UPDATED_AT]: -1 }) // Sort by updatedAt in descending order
      .toArray();
  
    return chatRooms.map((chatRoom) => {
      if (chatRoom[FIELDS.ROOM_TYPE] === "dm") {
        // If DM, remove the current user from participants
        chatRoom[FIELDS.PARTICIPANTS] = chatRoom[FIELDS.PARTICIPANTS].filter((id) => id !== userId);
      } else if (chatRoom[FIELDS.ROOM_TYPE] === "group") {
        // If Group, check if the user is still active or removed
        const currentUser = chatRoom[FIELDS.PARTICIPANTS].find((participant) => participant.userId === userId);
        chatRoom.isPart = currentUser?.status === "active"; // True if active, false otherwise
      }
  
      return chatRoom;
    });
  }
  
  
  

  async updateGroupProfile(chatRoomId, profileData) {
    const { profileUrl, groupName, bio } = profileData;
    const updateFields = {};
    if (profileUrl) updateFields[FIELDS.PROFILE_URL] = profileUrl;
    if (groupName) updateFields.groupName = groupName;
    if (bio) updateFields.bio = bio;

    return this.collection.updateOne(
      { [FIELDS.CHAT_ROOM_ID]: chatRoomId },
      { $set: { ...updateFields, [FIELDS.UPDATED_AT]: new Date() } }
    );
  }

  async deleteChatRoom(chatRoomId) {
    return this.collection.deleteOne({ [FIELDS.CHAT_ROOM_ID]: chatRoomId });
  }

  async leaveChatRoom(chatRoomId, userId) {
    return this.collection.updateOne(
      {
        [FIELDS.CHAT_ROOM_ID]: chatRoomId,
        [`${FIELDS.PARTICIPANTS}.userId`]: userId,
      },
      {
        $set: {
          [`${FIELDS.PARTICIPANTS}.$.status`]: "left",
          [FIELDS.UPDATED_AT]: new Date(),
        },
      }
    );
  }


  async checkUserExistenceInRoom(senderId, entityId) {
    try {
      const where = {
        [FIELDS.CHAT_ROOM_ID]: entityId,
        $or: [
          {
          [FIELDS.ROOM_TYPE]:"dm",
          [FIELDS.PARTICIPANTS]: senderId,
        },

        {
          [FIELDS.ROOM_TYPE]:"group",
          [FIELDS.PARTICIPANTS]: { $elemMatch: { userId: senderId, status: "active" } },
        },
        ]
         // Directly checks for the senderId in the array
      };
  
      const data = await this.collection.find(where).toArray();
  
      // Return true if the user exists in the room, false otherwise
      return data.length > 0;
    } catch (err) {
      throw new Error(`Error checking user existence in room: ${err.message}`);
    }
  }
  
  
}

module.exports = {
  instance: new ChatRooms(),
  FIELDS,
};
