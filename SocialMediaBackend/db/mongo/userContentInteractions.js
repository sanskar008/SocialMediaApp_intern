const { MongoDB } = require("./db");
const collectionName = "userContentInteractions";
const moment = require("moment");

const FIELDS = {
  USER_ID: 'user_id',
  FEED_ID: 'feed_id',
  POST_AUTHOR: 'post_author',
  ENTITIES: 'entities',
  CREATED_AT: 'created_at',
  FEED_CREATED_AT: 'feed_created_at',
  ACTION_TYPE: 'action_type' 
}

class UserContentInteractions extends MongoDB {
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

    async insertReplicable(params) { // for shares
        const insertionSet = {
            ...params,
            [FIELDS.CREATED_AT]: moment().unix()
        };

        try {
            const data = await this.collection.insertOne(insertionSet);
            data.originalData = insertionSet;
            return data;
        } catch (err) {
            console.error("Error inserting replicable:", err);
            throw err;
        }
    }

    async fetchTags(userId, limitTimestamp = null) {
        const monthAgoTimestamp = Math.floor(new Date().getTime() / 1000) - 30 * 24 * 60 * 60;
        const where = {
            $match: {
                [FIELDS.USER_ID]: userId,
                [FIELDS.CREATED_AT]: {
                    $gte: limitTimestamp || monthAgoTimestamp
                }
            }
        };

        try {
            const data = await this.collection.aggregate([
                where,
                { $unwind: "$entities" },
                {
                    $group: {
                        _id: "$entities",
                        count: { $sum: 1 }
                    }
                },
                { $sort: { count: -1 } }
            ]).toArray();
            return data;
        } catch (err) {
            console.error("Error fetching tags:", err);
            throw err;
        }
    }

    async fetchTrendingFeedIds(limitTimestamp = null, limit = 100) {
        const monthAgoTimestamp = Math.floor(new Date().getTime() / 1000) - 30 * 24 * 60 * 60;
        const where = {
            $match: {
                [FIELDS.CREATED_AT]: {
                    $gte: limitTimestamp || monthAgoTimestamp
                }
            }
        };

        try {
            const data = await this.collection.aggregate([
                where,
                { 
                    $group: { 
                        _id: { feed_id: "$feed_id", action_type: "$action_type" }, 
                        count: { $sum: 1 } 
                    } 
                },
                { 
                    $project: { 
                        _id: "$_id.feed_id",
                        action_type: "$_id.action_type", 
                        count: "$count" 
                    } 
                },
                { $sort: { count: -1 } },
                { $limit: limit }
            ]).toArray();
            return data;
        } catch (err) {
            console.error("Error fetching trending feed IDs:", err);
            throw err;
        }
    }

    async fetchTrendingKeywords(limitTimestamp = null, limit = 100) {
        const monthAgoTimestamp = Math.floor(new Date().getTime() / 1000) - 30 * 24 * 60 * 60;
        const where = {
            $match: {
                [FIELDS.CREATED_AT]: {
                    $gte: limitTimestamp || monthAgoTimestamp
                }
            }
        };

        try {
            const data = await this.collection.aggregate([
                where,
                { $unwind: "$entities" },
                { $group: { _id: "$entities", count: { $sum: 1 } } },
                { $sort: { count: -1 } },
                { $limit: limit }
            ]).toArray();
            return data;
        } catch (err) {
            console.error("Error fetching trending keywords:", err);
            throw err;
        }
    }

    async insert(params) {
        const where = {
            [FIELDS.USER_ID]: params[FIELDS.USER_ID],
            [FIELDS.FEED_ID]: params[FIELDS.FEED_ID],
            [FIELDS.ACTION_TYPE]: params[FIELDS.ACTION_TYPE]
        }
        const insertionSet = {
            $set: {
                ...params,
                [FIELDS.CREATED_AT]: moment().unix()
            },
        };

        try {
            const data = await this.collection.updateOne(
                where,
                insertionSet,
                { upsert: true }
            );
            data.originalData = insertionSet;
            return data;
        } catch (err) {
            console.error("Error inserting data:", err);
            throw err;
        }
    }
}

module.exports = {
  instance: new UserContentInteractions(),
  FIELDS
};