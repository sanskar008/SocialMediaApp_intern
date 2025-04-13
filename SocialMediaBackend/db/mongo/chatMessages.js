const { MongoDB } = require("./db");
const collectionName = "chatMessages";

const FIELDS = {
  MESSAGE_ID: "_id",
  CONTENT: "content",
  MEDIA: "media",
  SENDER_ID: "senderId",
  ROOM_ID: "roomId",
  CREATED_AT: "createdAt",
  ENTITY: 'entity',
  REACTIONS: 'reactions',
  REPLY_TO: 'replyTo',
  MESSAGE_STATUS: 'messageStatus',
  SEEN_BY: 'seenBy',
  MEDIA_TYPE: 'mediaType'
};

class ChatMessages extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    const db = await super.getDBInstance();
    this.collection = db.collection(collectionName);
  }

  async createMessage(content, senderId, roomId, media = null, entity, replyTo = null) {
    try {
      const message = {
        [FIELDS.CONTENT]: content,
        [FIELDS.SENDER_ID]: senderId,
        [FIELDS.ROOM_ID]: roomId,
        [FIELDS.MEDIA]: media,
        [FIELDS.CREATED_AT]: new Date(),
        [FIELDS.ENTITY]: entity,
        [FIELDS.REACTIONS]: [],
        [FIELDS.REPLY_TO]: replyTo,
        [FIELDS.MESSAGE_STATUS]: 'sent',
        [FIELDS.SEEN_BY]: [],
        [FIELDS.MEDIA_TYPE]: media ? this.getMediaType(media) : null
      };

      const result = await this.collection.insertOne(message);

      if (result.insertedId) {
        return { ...message, [FIELDS.MESSAGE_ID]: result.insertedId };
      }

      throw new Error("Failed to create chat message");
    } catch (error) {
      console.error("Error creating message:", error);
      throw error;
    }
  }

  getMediaType(media) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    const videoExtensions = ['mp4', 'webm', 'mov'];
    const audioExtensions = ['mp3', 'wav', 'ogg'];
    
    const extension = media.split('.').pop().toLowerCase();
    
    if (imageExtensions.includes(extension)) return 'image';
    if (videoExtensions.includes(extension)) return 'video';
    if (audioExtensions.includes(extension)) return 'audio';
    return 'file';
  }

  async addReaction(messageId, userId, reaction) {
    return this.collection.updateOne(
      { [FIELDS.MESSAGE_ID]: messageId },
      { 
        $push: { 
          [FIELDS.REACTIONS]: {
            userId,
            reaction,
            timestamp: new Date()
          }
        }
      }
    );
  }

  async removeReaction(messageId, userId) {
    return this.collection.updateOne(
      { [FIELDS.MESSAGE_ID]: messageId },
      { 
        $pull: { 
          [FIELDS.REACTIONS]: { userId }
        }
      }
    );
  }

  async markMessageAsSeen(messageId, userId) {
    return this.collection.updateOne(
      { 
        [FIELDS.MESSAGE_ID]: messageId,
        [FIELDS.SEEN_BY]: { $ne: userId }
      },
      { 
        $push: { [FIELDS.SEEN_BY]: userId }
      }
    );
  }

  async updateMessageStatus(messageId, status) {
    return this.collection.updateOne(
      { [FIELDS.MESSAGE_ID]: messageId },
      { $set: { [FIELDS.MESSAGE_STATUS]: status } }
    );
  }

  /**
   * Fetch paginated messages for a chat room.
   * @param {string} roomId - ID of the chat room
   * @param {number} page - Current page number
   * @param {number} limit - Number of messages per page
   * @returns {object} { messages: [], totalMessages, totalPages }
   */
  async getMessagesByRoomId(roomId, page = 1, limit = 20, timestamp = null) {
    try {
      const skip = (page - 1) * limit;

      const totalMessages = await this.collection.countDocuments({ [FIELDS.ROOM_ID]: roomId });
      const totalPages = Math.ceil(totalMessages / limit);

      const query = { [FIELDS.ROOM_ID]: roomId };

      if (timestamp) {
        const date = new Date(timestamp);
        const sevenDaysAgo = new Date(date);
        sevenDaysAgo.setDate(date.getDate() - 7);
        query[FIELDS.CREATED_AT] = { $gte: sevenDaysAgo };
      }

      const messages = await this.collection
        .find(query)
        .sort({ [FIELDS.CREATED_AT]: -1 })
        .skip(skip)
        .limit(limit)
        .toArray();

      // If there are reply messages, fetch the original messages
      const replyMessageIds = messages
        .filter(msg => msg[FIELDS.REPLY_TO])
        .map(msg => msg[FIELDS.REPLY_TO]);

      const replyMessages = await this.collection
        .find({ [FIELDS.MESSAGE_ID]: { $in: replyMessageIds } })
        .toArray();

      // Map reply messages to their IDs for easy lookup
      const replyMessagesMap = replyMessages.reduce((acc, msg) => {
        acc[msg[FIELDS.MESSAGE_ID]] = msg;
        return acc;
      }, {});

      // Attach reply messages to the original messages
      const messagesWithReplies = messages.map(msg => ({
        ...msg,
        replyToMessage: msg[FIELDS.REPLY_TO] ? replyMessagesMap[msg[FIELDS.REPLY_TO]] : null
      }));

      return {
        messages: messagesWithReplies,
        totalMessages,
        totalPages,
      };
    } catch (error) {
      console.error("Error fetching paginated messages:", error);
      throw new Error("Failed to fetch messages.");
    }
  }

  async getLast10Messages(roomId) {
    // Reuse the paginated messages function with page 1 and limit 10
    const { messages } = await this.getMessagesByRoomId(roomId, 1, 10);
    return messages;
  }

  async getMessageById(messageId) {
    return this.collection.findOne({ [FIELDS.MESSAGE_ID]: messageId });
  }

  async deleteMessage(messageId) {
    return this.collection.deleteOne({ [FIELDS.MESSAGE_ID]: messageId });
  }
}

module.exports = {
  instance: new ChatMessages(),
  FIELDS,
};
