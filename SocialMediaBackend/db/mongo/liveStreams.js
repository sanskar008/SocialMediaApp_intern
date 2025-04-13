const { MongoDB } = require("./db");
const collectionName = "liveStreams";

const FIELDS = {
    USER_ID: "userId",           // User starting the live stream
    CHANNEL_NAME: "channelName", // Agora channel name for the live stream
    IS_LIVE: "isLive",           // Boolean to indicate if the user is live
    CREATED_AT: "createdAt",     // Timestamp for when the record was created
    UPDATED_AT: "updatedAt",     // Timestamp for when the record was last updated
};

class LiveStreams extends MongoDB {
    constructor() {
        super();
    }

    async init() {
        const db = await super.getDBInstance();
        this.collection = db.collection(collectionName);
    }

    /**
     * Get active live streams for multiple userIds
     * @param {Array} userIds - List of userIds to fetch live streams for
     * @returns {Array} Active live streams for the given userIds
     */
    async getActiveLiveStreams(userIds) {
        try {
            return await this.collection
                .find({
                    [FIELDS.USER_ID]: { $in: userIds },
                    [FIELDS.IS_LIVE]: true, // Only fetch live users
                })
                .toArray();
        } catch (error) {
            console.error("Error fetching active live streams:", error.message);
            throw new Error("Failed to fetch active live streams.");
        }
    }

    /**
     * Start or update a live stream
     */
    async startLiveStream({ userId, channelName }) {
        const now = new Date();

        const result = await this.collection.updateOne(
            { [FIELDS.USER_ID]: userId }, // Find by userId
            {
                $set: {
                    [FIELDS.IS_LIVE]: true,
                    [FIELDS.CHANNEL_NAME]: channelName,
                    [FIELDS.UPDATED_AT]: now,
                },
                $setOnInsert: {
                    [FIELDS.CREATED_AT]: now, // Set createdAt only if it's a new document
                },
            },
            { upsert: true } // Insert if no matching record exists
        );

        if (!result) {
            throw new Error("Failed to start or update live stream.");
        }

        return result;
    }

    /**
     * End a live stream
     */
    async endLiveStream(userId) {
        const now = new Date();

        const result = await this.collection.updateOne(
            { [FIELDS.USER_ID]: userId },
            {
                $set: {
                    [FIELDS.IS_LIVE]: false,
                    [FIELDS.CHANNEL_NAME]: null, // Remove channel name
                    [FIELDS.UPDATED_AT]: now,
                },
            }
        );

        if (result.modifiedCount === 0) {
            throw new Error("Failed to end live stream or live stream not found.");
        }

        return result;
    }

    /**
     * Join a live stream
     */
    async getLiveStreamByUserId(userId) {
        return this.collection.findOne({
            [FIELDS.USER_ID]: userId,
            [FIELDS.IS_LIVE]: true, // Ensure the user is live
        });
    }
}

module.exports = {
    instance: new LiveStreams(),
    FIELDS,
};
