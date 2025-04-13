const { MongoDB } = require("./db");
const collectionName = "messageInteractions";

const FIELDS = {
  INTERACTION_ID: "_id", // MongoDB auto-generated ID
  MESSAGE_ID: "messageId", // Associated message ID
  USER_ID: "userId", // ID of the user interacting with the message
  STATUS: "status", // Interaction status (e.g., "seen", "delivered", "deleted")
  CREATED_AT: "createdAt", // Timestamp when the interaction was created
  UPDATED_AT: "updatedAt", // Timestamp when the interaction was last updated
};

class MessageInteractions extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    const db = await super.getDBInstance();
    this.collection = db.collection(collectionName);
  }

  async createInteraction(messageId, userId, status) {
    const interaction = {
      [FIELDS.MESSAGE_ID]: messageId,
      [FIELDS.USER_ID]: userId,
      [FIELDS.STATUS]: status,
      [FIELDS.CREATED_AT]: new Date(),
      [FIELDS.UPDATED_AT]: new Date(),
    };

    const result = await this.collection.insertOne(interaction);

    if (result.insertedId) {
      return { ...interaction, [FIELDS.INTERACTION_ID]: result.insertedId };
    }

    throw new Error("Failed to create message interaction");
  }

  async getInteractionsByMessageId(messageId) {
    return this.collection.find({ [FIELDS.MESSAGE_ID]: messageId.toString() }).toArray();
  }

  // Inside MessageInteractions class

  async getUnseenCountForMessages(messages, userId) {
    let unseenCount = 0;
    for (const message of messages) {
      const interactions = await this.getInteractionsByMessageId(message._id);
      // Check if the message has been seen by the user
      if (message.senderId === userId || interactions.some(interaction => interaction.userId === userId && interaction.status === "seen")) {
        break; // Stop counting when the first seen message is encountered
      }
      unseenCount++;
    }
    return unseenCount;
  }


  async updateInteractionStatus(messageId, userId, status) {
    const result = await this.collection.updateOne(
      { [FIELDS.MESSAGE_ID]: messageId, [FIELDS.USER_ID]: userId },
      {
        $set: {
          [FIELDS.STATUS]: status,
          [FIELDS.UPDATED_AT]: new Date(),
        },
      }
    );

    if (!result.modifiedCount) {
      throw new Error("Failed to update interaction status or interaction not found");
    }

    return result;
  }

  async deleteInteraction(interactionId) {
    return this.collection.deleteOne({ [FIELDS.INTERACTION_ID]: interactionId });
  }
}

module.exports = {
  instance: new MessageInteractions(),
  FIELDS,
};
