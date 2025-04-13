const { MongoDB } = require("./db");
const moment = require('moment');
const collectionName = "blockedUsers";

const FIELDS = {
  BLOCKER: "blocker",         // The user who is blocking another user
  BLOCKED: "blocked",         // The user who is being blocked
  CREATED_AT: "createdAt",    // Timestamp for when the block was created
  UPDATED_AT: "updatedAt",    // Timestamp for when the block was last updated
};

class BlockedUsers extends MongoDB {
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

  /**
   * Block a user.
   * If a block record already exists, update the timestamp.
   * @param {Object} param0 - Object containing the blocker and blocked user IDs.
   * @returns {Object} MongoDB operation result.
   */
  async blockUser({ blocker, blocked }) {
    try {
      const now = moment().unix();
      const filter = {
        [FIELDS.BLOCKER]: blocker,
        [FIELDS.BLOCKED]: blocked
      };

      // Check if the block record already exists
      const existingBlock = await this.collection.findOne(filter);
      if (existingBlock) {
        // Update the updatedAt field if already blocked
        const updateResult = await this.collection.updateOne(filter, {
          $set: { [FIELDS.UPDATED_AT]: now }
        });
        return updateResult;
      } else {
        const blockData = {
          [FIELDS.BLOCKER]: blocker,
          [FIELDS.BLOCKED]: blocked,
          [FIELDS.CREATED_AT]: now,
          [FIELDS.UPDATED_AT]: now,
        };
        const insertResult = await this.collection.insertOne(blockData);
        return insertResult;
      }
    } catch (err) {
      console.error("Error blocking user:", err.message);
      throw err;
    }
  }

  /**
   * Unblock a user.
   * @param {Object} param0 - Object containing the blocker and blocked user IDs.
   * @returns {Object} MongoDB operation result.
   */
  async unblockUser({ blocker, blocked }) {
    try {
      const result = await this.collection.deleteOne({
        [FIELDS.BLOCKER]: blocker,
        [FIELDS.BLOCKED]: blocked,
      });
      if (result.deletedCount === 0) {
        throw new Error("No block record found for the given users");
      }
      return result;
    } catch (err) {
      console.error("Error unblocking user:", err.message);
      throw err;
    }
  }

  /**
   * Check if a user has blocked another user.
   * @param {Object} param0 - Object containing the blocker and blocked user IDs.
   * @returns {Boolean} True if a block exists, otherwise false.
   */
  async isBlocked({ blocker, blocked }) {
    try {
      const blockRecord = await this.collection.findOne({
        [FIELDS.BLOCKER]: blocker,
        [FIELDS.BLOCKED]: blocked,
      });
      return blockRecord !== null;
    } catch (err) {
      console.error("Error checking block status:", err.message);
      throw err;
    }
  }

  /**
   * Get a list of users that a specific user has blocked.
   * @param {String} blocker - The user ID who performed the block.
   * @returns {Array} List of block records for the given blocker.
   */
  async getBlockedUsers(blocker) {
    try {
      const records = await this.collection.find({
        [FIELDS.BLOCKER]: blocker,
      }).toArray();
      return records;
    } catch (err) {
      console.error("Error fetching blocked users:", err.message);
      throw err;
    }
  }

  /**
   * Get a list of users who have blocked a specific user.
   * @param {String} blocked - The user ID who might have been blocked.
   * @returns {Array} List of block records where the user is blocked.
   */
  async getUsersWhoBlocked(blocked) {
    try {
      const records = await this.collection.find({
        [FIELDS.BLOCKED]: blocked,
      }).toArray();
      return records;
    } catch (err) {
      console.error("Error fetching users who blocked:", err.message);
      throw err;
    }
  }

  /**
   * Retrieve all block records with optional pagination.
   * @param {Object} options - Options for pagination (skip and limit).
   * @returns {Array} List of block records.
   */
  async getAllBlocks({ skip = 0, limit = 10 } = {}) {
    try {
      const records = await this.collection.find({})
        .skip(skip)
        .limit(limit)
        .toArray();
      return records;
    } catch (err) {
      console.error("Error fetching all block records:", err.message);
      throw err;
    }
  }
}

module.exports = {
  instance: new BlockedUsers(),
  FIELDS,
};
