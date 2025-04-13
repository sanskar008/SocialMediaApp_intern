const { MongoDB } = require("./db");
const collectionName = "bannedUsers";
const moment = require("moment");

const FIELDS = {
  ID: '_id',
  USER_ID: 'userId',
  STATUS: 'status',
  BANNED_ON: 'bannedOn',
  BANNED_TILL: 'bannedTill',
  TIMES: 'times',
  REASON: 'reason',
  MODERATOR_ID: 'moderatorId'
}

const FIELD_VALUES = {
  [FIELDS.STATUS]: {
    ACTIVE: 1,
    INACTIVE: 0,
    PERMANENT: 2
  }
}

class BannedUsers extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    if (!this.collection) {
      const db = await super.getDBInstance();
      this.collection = db.collection(collectionName);
    }
  }

  getCollectionInstance() {
    return this.collection;
  }

  async banUser(userId, banTill, reason = '', moderatorId = null) {
    try {
      // Ensure collection is initialized
      await this.init(); 
      
      const objectId = super.getObjectIdFromString(userId);
      const now = new Date();
      const banTillDate = new Date(banTill);
  
      // Safely deactivate previous bans (only if collection exists)
      if (this.collection) {
        await this.collection.updateMany(
          { 
            [FIELDS.USER_ID]: objectId,
            [FIELDS.STATUS]: { 
              $in: [
                FIELD_VALUES[FIELDS.STATUS].ACTIVE,
                FIELD_VALUES[FIELDS.STATUS].PERMANENT
              ] 
            }
          },
          { $set: { [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].INACTIVE } }
        );
      }
  
      // Get ban count (returns 0 if collection doesn't exist)
      const previousBansCount = this.collection 
        ? await this.collection.countDocuments({ [FIELDS.USER_ID]: objectId })
        : 0;
  
      const isPermanent = banTillDate.getFullYear() > 9998;
  
      const banData = {
        [FIELDS.USER_ID]: objectId,
        [FIELDS.STATUS]: isPermanent ? FIELD_VALUES[FIELDS.STATUS].PERMANENT : FIELD_VALUES[FIELDS.STATUS].ACTIVE,
        [FIELDS.BANNED_ON]: now,
        [FIELDS.BANNED_TILL]: banTillDate,
        [FIELDS.TIMES]: previousBansCount + 1,
        [FIELDS.REASON]: reason,
        [FIELDS.MODERATOR_ID]: moderatorId
      };
  
      // Create collection implicitly by inserting first document
      const result = await this.collection.insertOne(banData);
      
      return {
        id: result.insertedId,
        userId: userId,
        status: banData[FIELDS.STATUS],
        bannedOn: banData[FIELDS.BANNED_ON],
        bannedTill: banData[FIELDS.BANNED_TILL],
        reason: banData[FIELDS.REASON],
        times: banData[FIELDS.TIMES],
        isPermanent: isPermanent
      };
    } catch (err) {
      console.error("Error banning user:", err.message);
      throw new Error("Failed to process ban request");
    }
  }

  async getActiveBan(userId) {
    try {
      const objectId = super.getObjectIdFromString(userId);
      const now = new Date();

      return await this.collection.findOne({
        [FIELDS.USER_ID]: objectId,
        [FIELDS.STATUS]: { 
          $in: [
            FIELD_VALUES[FIELDS.STATUS].ACTIVE,
            FIELD_VALUES[FIELDS.STATUS].PERMANENT
          ] 
        },
        $or: [
          { [FIELDS.BANNED_TILL]: { $gt: now } },
          { [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].PERMANENT }
        ]
      });
    } catch (err) {
      console.error("Error getting active ban:", err.message);
      throw err;
    }
  }

  async isUserBanned(userId) {
    try {
      const activeBan = await this.getActiveBan(userId);
      if (!activeBan) return { isBanned: false };

      return {
        isBanned: true,
        banId: activeBan._id,
        bannedTill: activeBan[FIELDS.BANNED_TILL],
        bannedOn: activeBan[FIELDS.BANNED_ON],
        reason: activeBan[FIELDS.REASON],
        times: activeBan[FIELDS.TIMES],
        moderatorId: activeBan[FIELDS.MODERATOR_ID],
        isPermanent: activeBan[FIELDS.STATUS] === FIELD_VALUES[FIELDS.STATUS].PERMANENT
      };
    } catch (err) {
      console.error("Error checking if user is banned:", err.message);
      throw err;
    }
  }

  async unbanUser(userId) {
    try {
      const objectId = super.getObjectIdFromString(userId);

      const result = await this.collection.updateMany(
        { 
          [FIELDS.USER_ID]: objectId,
          [FIELDS.STATUS]: { 
            $in: [
              FIELD_VALUES[FIELDS.STATUS].ACTIVE,
              FIELD_VALUES[FIELDS.STATUS].PERMANENT
            ] 
          }
        },
        { $set: { [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].INACTIVE } }
      );

      return {
        success: result.modifiedCount > 0,
        count: result.modifiedCount
      };
    } catch (err) {
      console.error("Error unbanning user:", err.message);
      throw err;
    }
  }

  async getBanHistory(userId, page = 1, limit = 10) {
  try {
    if (!this.collection) {
      throw new Error("Database collection not initialized");
    }

    const objectId = super.getObjectIdFromString(userId);
    const skip = (page - 1) * limit;

    const [bans, total] = await Promise.all([
      this.collection.find({ 
        [FIELDS.USER_ID]: objectId 
      })
      .sort({ [FIELDS.BANNED_ON]: -1 })
      .skip(skip)
      .limit(limit)
      .toArray(),

      this.collection.countDocuments({ 
        [FIELDS.USER_ID]: objectId 
      })
    ]);

    return {
      total,
      page,
      limit,
      bans: bans.map(ban => ({
        id: ban._id,
        userId: ban[FIELDS.USER_ID],
        status: ban[FIELDS.STATUS],
        bannedOn: ban[FIELDS.BANNED_ON],
        bannedTill: ban[FIELDS.BANNED_TILL],
        reason: ban[FIELDS.REASON],
        times: ban[FIELDS.TIMES],
        moderatorId: ban[FIELDS.MODERATOR_ID]
      }))
    };

  } catch (err) {
    console.error("Database operation failed:", err.message);
    throw new Error("Failed to retrieve ban history. Please try again later.");
  }
}

  async getActiveBans(page = 1, limit = 10) {
    try {
      const now = new Date();
      const skip = (page - 1) * limit;

      const [bans, total] = await Promise.all([
        this.collection.find({
          [FIELDS.STATUS]: { 
            $in: [
              FIELD_VALUES[FIELDS.STATUS].ACTIVE,
              FIELD_VALUES[FIELDS.STATUS].PERMANENT
            ] 
          },
          $or: [
            { [FIELDS.BANNED_TILL]: { $gt: now } },
            { [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].PERMANENT }
          ]
        })
        .sort({ [FIELDS.BANNED_ON]: -1 })
        .skip(skip)
        .limit(limit)
        .toArray(),
        this.collection.countDocuments({
          [FIELDS.STATUS]: { 
            $in: [
              FIELD_VALUES[FIELDS.STATUS].ACTIVE,
              FIELD_VALUES[FIELDS.STATUS].PERMANENT
            ] 
          },
          $or: [
            { [FIELDS.BANNED_TILL]: { $gt: now } },
            { [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].PERMANENT }
          ]
        })
      ]);

      return {
        total,
        page,
        limit,
        bans: bans.map(ban => ({
          id: ban._id,
          userId: ban[FIELDS.USER_ID],
          status: ban[FIELDS.STATUS],
          bannedOn: ban[FIELDS.BANNED_ON],
          bannedTill: ban[FIELDS.BANNED_TILL],
          reason: ban[FIELDS.REASON],
          times: ban[FIELDS.TIMES],
          moderatorId: ban[FIELDS.MODERATOR_ID],
          isPermanent: ban[FIELDS.STATUS] === FIELD_VALUES[FIELDS.STATUS].PERMANENT
        }))
      };
    } catch (err) {
      console.error("Error getting active bans:", err.message);
      throw err;
    }
  }

  async cleanupExpiredBans() {
    try {
      const now = new Date();
      
      const result = await this.collection.updateMany(
        {
          [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].ACTIVE,
          [FIELDS.BANNED_TILL]: { $lte: now }
        },
        { $set: { [FIELDS.STATUS]: FIELD_VALUES[FIELDS.STATUS].INACTIVE } }
      );

      return {
        success: result.modifiedCount > 0,
        count: result.modifiedCount
      };
    } catch (err) {
      console.error("Error cleaning up expired bans:", err.message);
      throw err;
    }
  }
}

module.exports = {
  instance: new BannedUsers(),
  FIELDS,
  FIELD_VALUES,
};