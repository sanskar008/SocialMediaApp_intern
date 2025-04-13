const { MongoDB } = require("./db");
const collectionName = "recentSearches";
const moment = require("moment");

const FIELDS = {
  ID: '_id',
  USER_ID: 'userId',
  SEARCHED_USERS: 'searchedUsers',
  UPDATED_AT: 'updatedAt'
}

class RecentSearches extends MongoDB {
  constructor() {
    super();
  }

  async init() {
    if (!this.collection) {
      const db = await super.getDBInstance();
      this.collection = db.collection(collectionName);
      
      // Create index for faster queries
      await this.collection.createIndex({ [FIELDS.USER_ID]: 1 }, { unique: true });
    }
  }

  getCollectionInstance() {
    return this.collection;
  }

  /**
   * Add or update a user's recent searches
   * @param {string} userId - The user who performed the search
   * @param {string} searchedUserId - The user who was searched for
   * @returns {Promise<Object>} - The updated recent searches document
   */
  async addRecentSearch(userId, searchedUserId) {
    try {
      // First, remove the searched user if they already exist in the array
      await this.collection.updateOne(
        { [FIELDS.USER_ID]: userId },
        { $pull: { [FIELDS.SEARCHED_USERS]: searchedUserId } }
      );

      // Then add the searched user to the beginning of the array and update timestamp
      const result = await this.collection.findOneAndUpdate(
        { [FIELDS.USER_ID]: userId },
        { 
          $push: { 
            [FIELDS.SEARCHED_USERS]: {
              $each: [searchedUserId],
              $position: 0,
              $slice: 50 // Limit to 50 most recent searches
            }
          },
          $set: { [FIELDS.UPDATED_AT]: moment().toDate() },
          $setOnInsert: { [FIELDS.USER_ID]: userId } // Create document if it doesn't exist
        },
        { 
          upsert: true,
          returnDocument: "after"
        }
      );

      return result;
    } catch (err) {
      console.error("Error adding recent search:", err.message);
      throw err;
    }
  }

  /**
   * Remove a user from recent searches
   * @param {string} userId - The user who performed the searches
   * @param {string} searchedUserId - The user to remove from recent searches
   * @returns {Promise<Object>} - The update result
   */
  async removeRecentSearch(userId, searchedUserId) {
    try {
      const result = await this.collection.updateOne(
        { [FIELDS.USER_ID]: userId },
        { 
          $pull: { [FIELDS.SEARCHED_USERS]: searchedUserId },
          $set: { [FIELDS.UPDATED_AT]: moment().toDate() }
        }
      );

      return result;
    } catch (err) {
      console.error("Error removing recent search:", err.message);
      throw err;
    }
  }

  /**
   * Clear all recent searches for a user
   * @param {string} userId - The user whose recent searches to clear
   * @returns {Promise<Object>} - The delete result
   */
  async clearRecentSearches(userId) {
    try {
      const result = await this.collection.updateOne(
        { [FIELDS.USER_ID]: userId },
        { 
          $set: { 
            [FIELDS.SEARCHED_USERS]: [],
            [FIELDS.UPDATED_AT]: moment().toDate()
          }
        }
      );

      return result;
    } catch (err) {
      console.error("Error clearing recent searches:", err.message);
      throw err;
    }
  }

  /**
   * Get recent searches for a user
   * @param {string} userId - The user to get recent searches for
   * @param {number} limit - Maximum number of recent searches to return
   * @returns {Promise<Array>} - Array of searched user IDs in recent order
   */
  async getRecentSearches(userId, limit = 20) {
    try {
      const result = await this.collection.findOne(
        { [FIELDS.USER_ID]: userId },
        { projection: { [FIELDS.SEARCHED_USERS]: { $slice: limit } } }
      );

      return result?.searchedUsers || [];
    } catch (err) {
      console.error("Error getting recent searches:", err.message);
      throw err;
    }
  }

  /**
   * Check if a user exists in another user's recent searches
   * @param {string} userId - The user who performed searches
   * @param {string} searchedUserId - The user to check for
   * @returns {Promise<boolean>} - Whether the user exists in recent searches
   */
  async isInRecentSearches(userId, searchedUserId) {
    try {
      const result = await this.collection.findOne({
        [FIELDS.USER_ID]: userId,
        [FIELDS.SEARCHED_USERS]: searchedUserId
      });

      return !!result;
    } catch (err) {
      console.error("Error checking recent searches:", err.message);
      throw err;
    }
  }
}

module.exports = {
  instance: new RecentSearches(),
  FIELDS
};