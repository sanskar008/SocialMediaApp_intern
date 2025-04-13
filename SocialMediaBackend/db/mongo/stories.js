const { MongoDB } = require("./db");
const moment = require('moment');
const collectionName = "stories";


const FIELDS = {
  _ID: '_id',
  CREATED_AT: 'createdAt',
  UPDATED_AT: 'updatedAt',
  URL: 'url',
  CONTENT_TYPE: 'contentType',
  REPLIES_ENABLED: 'repliesEnabled',
  TAGGED_USERS: 'taggedUsers',
  AUTHOR: 'author',
  PRIVACY: 'privacy',
  PRIVATE_TO: 'privateTo',
  HIDE_FROM: 'hideFrom',
  STATUS : 'status',
}

const FIELDS_VALUES ={
    
    [FIELDS.PRIVACY] : {
        'FRIENDS': 1,
        'NO_ONE' : 0,
        'PUBLIC': 2
    },

    [FIELDS.CONTENT_TYPE] : {
        TEXT: 'text',
        IMAGE: 'image',
        VIDEO: 'video',
    },

    [FIELDS.STATUS] : {
        LIVE : 1,
        ARCHIEVED : 0,
    }
}


class Stories extends MongoDB {
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

async insertStory(story) {
    try {
        const data = await this.collection.insertOne(story);
        data.originalData = story;
        return data;
    } catch (err) {
        throw err;
    }
}

async archieveStory(id) {
    try {
        const objectId = super.getObjectIdFromString(id);  
        const result = await this.collection.updateOne(
            { _id: objectId },
            { 
                $set: { 
                    [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].ARCHIEVED,  
                    [FIELDS.UPDATED_AT]: moment().unix()  
                }
            }
        );

        if (result.matchedCount === 0) {
            throw new Error('Story not found or already archived');
        }

        return result;
    } catch (err) {
        console.error('Error archiving story:', err.message);
        throw err;
    }
}


async getUserLatestActiveStory(userIds) {
    try {
        const where = {
            [FIELDS.AUTHOR]: { $in: userIds },
            [FIELDS.CREATED_AT]: { $gte: moment().subtract(24, 'hours').unix() },
            [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].LIVE,
        };
        const data = await this.collection
            .aggregate([
                { $match: where },
                { $sort: { [FIELDS.AUTHOR]: 1, [FIELDS.CREATED_AT]: -1 } },
                {
                    $group: {
                        _id: `$${FIELDS.AUTHOR}`,
                        data: { $first: "$$ROOT" },
                    },
                },
            ])
            .toArray();

        return data.map(item => ({ userId: item._id, data: item.data }));
    } catch (err) {
        throw err;
    }
}

async doesStoryBelongToUser(storyId, userId) {
    try {
      // Convert storyId to ObjectId
      const objectId = super.getObjectIdFromString(storyId);

      // Query to check if the story belongs to the user
      const where = {
        [FIELDS._ID]: objectId,
        [FIELDS.AUTHOR]: userId,
      };

      const story = await this.collection.findOne(where);

      // Return true if the story exists and belongs to the user, otherwise false
      return story !== null;
    } catch (err) {
      console.error('Error checking if story belongs to user:', err.message);
      throw err;
    }
  }

async getUserActiveStories(userIds) {
    try {
        const where = {
            [FIELDS.AUTHOR]: { $in: userIds },
            [FIELDS.CREATED_AT]: { $gte: moment().subtract(24, 'hours').unix() },
            [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].LIVE,
        };

        const data = await this.collection
            .find(where)
            .sort({ [FIELDS.AUTHOR]: 1, [FIELDS.CREATED_AT]: 1 })
            .toArray();

        const groupedStories = userIds.map(userId => {
            const storiesArray = data.filter(story => story[FIELDS.AUTHOR].toString() === userId.toString());
            return { userId, storiesArray };
        });

        return groupedStories;
    } catch (err) {
        throw err;
    }
}

async getStoryById(storyId) {
    try {
        const objectId = super.getObjectIdFromString(storyId);
        
        const story = await this.collection.findOne(
            { [FIELDS._ID]: objectId },
            {
                projection: {
                    [FIELDS.URL]: 1,
                    [FIELDS.CONTENT_TYPE]: 1,
                    [FIELDS.CREATED_AT]: 1,
                    [FIELDS.AUTHOR]: 1,
                    [FIELDS.PRIVACY]: 1,
                    [FIELDS.STATUS]: 1,
                    [FIELDS.REPLIES_ENABLED]: 1,
                    [FIELDS.TAGGED_USERS]: 1
                }
            }
        );

        if (!story) {
            throw new Error('Story not found');
        }

        return {
            id: story._id,
            url: story[FIELDS.URL],
            contentType: story[FIELDS.CONTENT_TYPE],
            createdAt: story[FIELDS.CREATED_AT],
            author: story[FIELDS.AUTHOR],
            privacy: story[FIELDS.PRIVACY],
            status: story[FIELDS.STATUS],
            repliesEnabled: story[FIELDS.REPLIES_ENABLED],
            taggedUsers: story[FIELDS.TAGGED_USERS] || []
        };
    } catch (err) {
        console.error('Error fetching story by ID:', err.message);
        throw err;
    }
}

async getStoryMetadata(storyId) {
    try {
        const where = {
            [FIELDS._ID]: super.getObjectIdFromString(storyId)
        };
        const projection = {
            [FIELDS._ID]: 0,
            [FIELDS.AUTHOR]: 1,
            [FIELDS.CREATED_AT]: 1,
        };
        const data = await this.collection.findOne(where, { projection });
        return data;
    } catch (err) {
        throw err;
    }
}
}

module.exports = {
  instance: new Stories(),
  FIELDS,
  FIELDS_VALUES
};