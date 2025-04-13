const { ObjectId } = require('mongodb');
const { MongoDB } = require("./db");
const collectionName = "calls";

const FIELDS = {
  FROM: "from",               // Caller userId
  TO: "to",                   // Callee userId (null for group calls)
  PARTICIPANTS: "participants", // Array of participants for group calls
  TYPE: "type",               // Call type: "audio", "video", "group"
  START_TIME: "startTime",     // Call initiation time
  END_TIME: "endTime",         // Call end time
  STATUS: "status",           // Call status: "missed", "ongoing", "ended"
  CHANNEL_NAME: "channelName", // Agora channel name
  CREATED_AT: "createdAt",    // Timestamp when the call record was created
  UPDATED_AT: "updatedAt",    // Timestamp when the call record was last updated
};

class Calls extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    const db = await super.getDBInstance();
    this.collection = db.collection(collectionName);
  }

  async getCallById(callId) {
    try {
        // Convert `callId` to ObjectId if it's a string
        const objectId = typeof callId === 'string' ? new ObjectId(callId) : callId;

        // Fetch the call record from the database
        const call = await this.collection.findOne({ _id: objectId });

        if (!call) {
            throw new Error('Call not found.');
        }

        return call;
    } catch (error) {
        console.error('Error fetching call by ID:', error.message);
        throw new Error('Failed to fetch call.');
    }
}

  async addToCall({userId, callId}){
    const now = new Date();
    const objectId = super.getObjectIdFromString(callId);
    // Add the new participant
    const newParticipant = {
      userId,
      status: "pending", // Default status
      joinedAt: null,    // Populated when the user joins
    };

    const result = await this.collection.updateOne(
      { _id: objectId },
      {
      $addToSet: { [FIELDS.PARTICIPANTS]: newParticipant },
      $set: { [FIELDS.UPDATED_AT]: now },
      }
    );

    if (result.modifiedCount === 0) {
      throw new Error('Failed to add participant.');
    }

    return result;
  }



  /**
   * Create a new call record
   */
  async createCall({ from, participants, channelName, type = "audio" , chatRoomId}) {
    const now = new Date();

    // Add `from` and `to` to the participants list if they are not already included
    const baseParticipants = [from];
    const uniqueParticipants = [...new Set([...baseParticipants, ...participants])];

    // Format participants with default statuses
    const formattedParticipants = uniqueParticipants.map((userId) => ({
        userId,
        status: userId === from ? "joined" : "pending", // Caller (`from`) is marked as "joined"
        joinedAt: userId === from ? now : null,        // Set joinedAt for the caller
    }));

    // Create the call object
    const call = {
        [FIELDS.FROM]: from,
        [FIELDS.TO]: chatRoomId,
        [FIELDS.TYPE]: type,
        [FIELDS.CHANNEL_NAME]: channelName,
        [FIELDS.PARTICIPANTS]: formattedParticipants,
        [FIELDS.START_TIME]: now,
        [FIELDS.STATUS]: "ringing", // Default status
        [FIELDS.CREATED_AT]: now,
        [FIELDS.UPDATED_AT]: now,
    };

    // Insert into the database
    const result = await this.collection.insertOne(call);

    if (result.insertedId) {
        // Return the newly created call document
        const insertedCall = await this.collection.findOne({ _id: result.insertedId });
        return insertedCall;
    }

    throw new Error("Failed to create call record");
}



  /**
   * Update call status and end time
   */
  async updateCallStatus(callId, status) {
    const updateFields = { [FIELDS.STATUS]: status, [FIELDS.UPDATED_AT]: new Date() };
  
    // If the call has ended, add the end time
    if (status === "ended") {
      updateFields[FIELDS.END_TIME] = new Date();
    }
  
    const result = await this.collection.findOneAndUpdate(
      { _id: new ObjectId(callId) },
      { $set: updateFields },
      { returnDocument: 'after' } // For MongoDB driver v4+; use { returnOriginal: false } for older versions
    );
  
    if (!result.value) {
      throw new Error("Call record not found or status not updated");
    }
  
    return result.value;
  }
  
  /**
 * Force-end an ongoing call by updating its status and that of every participant.
 * @param {string|ObjectId} callId - The call's ID.
 * @returns {Object} - The updated call document.
 */
async endCall(callId) {
  const now = new Date();
  const updateFields = {
    // Update the call's overall status and set end time
    status: "ended",
    endTime: now,
    updatedAt: now,
    // Update every participant's status to "ended"
    "participants.$[].status": "ended"
  };

  const result = await this.collection.findOneAndUpdate(
    { _id: new ObjectId(callId) },
    { $set: updateFields },
    { returnDocument: 'after' }
  );

  if (!result._id) {
    throw new Error("Call record not found or not updated");
  }
  return result;
}


  /**
   * Add participants to an existing call
   */
  async addParticipants(callId, participants) {
    const now = new Date();

    const formattedParticipants = participants.map((userId) => ({
      userId,
      status: "pending", // Default status
      joinedAt: null,    // Populated when the user joins
    }));

    const result = await this.collection.updateOne(
      { _id: callId },
      {
        $addToSet: {
          [FIELDS.PARTICIPANTS]: { $each: formattedParticipants }, // Add new participants
        },
        $set: { [FIELDS.UPDATED_AT]: now }, // Update the timestamp
      }
    );

    if (result.modifiedCount === 0) {
      throw new Error("Failed to add participants or call not found");
    }

    return result;
  }

  /**
   * Update participant status (e.g., "ongoing", "ended", "missed")
   */
  async updateParticipantStatus(callId, userId, status) {
    const now = new Date();
    const updateFields = {
      "participants.$.status": status,
      "participants.$.updatedAt": now,
    };
    if (status === "joined") {
      updateFields["participants.$.joinedAt"] = now;
    }
  
    // Update the status for the specified participant
    const result = await this.collection.findOneAndUpdate(
      {
        _id: new ObjectId(callId),
        "participants.userId": userId,
      },
      { $set: updateFields },
      { returnDocument: 'after' }
    );
  
    if (!result._id) {
      throw new Error("Call record not found or participant status not updated");
    }
  
    // Check if (n-1) or all participants have ended
    const call = result;
    const totalParticipants = call.participants.length;
    const endedCount = call.participants.filter(
      p => p.status === "ended" || p.status === "missed"
    ).length;
  
    // If n-1 or all participants have status 'ended'
    if (endedCount >= totalParticipants - 1) {
      const finalUpdate = {
        $set: {
          "participants.$[].status": "ended",  // Update all participants to ended
          status: "ended",                     // Update call's status to ended
          endTime: new Date(),                 // Set endTime for the call
          updatedAt: new Date()
        }
      };
      const updatedCall = await this.collection.findOneAndUpdate(
        { _id: new ObjectId(callId) },
        finalUpdate,
        { returnDocument: 'after' }
      );
      return updatedCall;
    }
  
    return call;
  }
  
  


  /**
   * Get all calls for a specific user
   */
  async getUserCalls(userId) {
    const calls = await this.collection
      .find({
        $or: [
          { [FIELDS.FROM]: userId },
          { [FIELDS.TO]: userId },
          { [FIELDS.PARTICIPANTS]: { $elemMatch: { userId } } },
        ],
      })
      .sort({ [FIELDS.UPDATED_AT]: -1 }) // Sort by updatedAt in descending order
      .toArray();

    return calls;
  }

  /**
   * Get ongoing calls for a user
   */
  async getOngoingCalls(userId) {
    const calls = await this.collection
      .find({
        [FIELDS.STATUS]: { $in: ["ongoing", "ringing"] }, // Match both "ongoing" and "ringing"
        $or: [
          { [FIELDS.FROM]: userId }, // Check if the user is the caller
          { [FIELDS.TO]: userId },   // Check if the user is the callee
          { [FIELDS.PARTICIPANTS]: { $elemMatch: { userId } } }, // Check if the user is a participant
        ],
      })
      .toArray();

    return calls;
  }


  /**
   * Delete a call record
   */
  async deleteCall(callId) {
    return this.collection.deleteOne({ _id: callId });
  }
}

module.exports = {
  instance: new Calls(),
  FIELDS,
};
