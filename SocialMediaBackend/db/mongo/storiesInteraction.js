const { MongoDB } = require("./db");
const collectionName = "storiesInteraction";

const FIELDS = {
  ID: '_id',
  STORY_ID: 'story_id',
  USER_ID: 'user_id',
  CREATED_AT: 'created_at',
};

class StoriesInteraction extends MongoDB {
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

  async saveInteraction(params) {
    const { storyId, userId } = params;
    const insert = {
      [FIELDS.STORY_ID]: storyId,
      [FIELDS.USER_ID]: userId,
      [FIELDS.CREATED_AT]: new Date(),
    };
  
    try {
      const existingInteraction = await this.collection.findOne({
        [FIELDS.STORY_ID]: storyId,
        [FIELDS.USER_ID]: userId,
      });
  
      if (existingInteraction) {
        console.log('Interaction already exists for this story and user.');
        return existingInteraction; 
      }
  
      const data = await this.collection.insertOne(insert);
      insert._id = data.insertedId; 
      return insert; 
    } catch (err) {
      console.error('Error saving interaction:', err.message);
      throw err;
    }
  }
  

  async getInteractionsByStory(storyId) {
    const where = {
      [FIELDS.STORY_ID]: storyId,
    };

    try {
      const data = await this.collection.find(where).sort({ [FIELDS.CREATED_AT]: -1 }).toArray();
      return data;
    } catch (err) {
      throw err;
    }
  }

  async hasStoriesBeenViewed(storyIds) {
    try {
      const where = {
        story_id: { $in: storyIds }, // Query the story_id field, not _id
      };
  
      // Fetch interactions for all given story IDs
      const interactions = await this.collection
        .find(where)
        .project({ story_id: 1 }) // Fetch only the story_id field to minimize data transfer
        .toArray();
  
      // Create a map of storyId to viewed status
      const someoneHasViewedMap = storyIds.reduce((acc, storyId) => {
        acc[storyId.toString()] = false; // Default to false
        return acc;
      }, {});
  
      interactions.forEach((interaction) => {
        someoneHasViewedMap[interaction.story_id.toString()] = true; // Mark as viewed if found
      });
  
      return someoneHasViewedMap;
    } catch (err) {
      console.error('Error checking if stories have been viewed:', err.message);
      throw err;
    }
  }

  async getStoriesViewedByUser(userId) {
    const where = {
      [FIELDS.USER_ID]: userId,
    };

    try {
      const data = await this.collection.find(where).sort({ [FIELDS.CREATED_AT]: -1 }).toArray();

      // Convert the data array into a dictionary
      const dictionary = data.reduce((acc, story) => {
        acc[story[FIELDS.STORY_ID]] = story;
        return acc;
      }, {});

      return dictionary;
    } catch (err) {
      throw err;
    }
}

  async countViewsByStory(storyId) {
    const where = {
      [FIELDS.STORY_ID]: storyId,
    };

    try {
      const count = await this.collection.countDocuments(where);
      return count;
    } catch (err) {
      throw err;
    }
  }

  async hasUserViewedStory(storyId, userId) {
    const where = {
      [FIELDS.STORY_ID]: storyId.toString(),
      [FIELDS.USER_ID]: userId,
    };

    try {
      const data = await this.collection.findOne(where);
      return data !== null;
    } catch (err) {
      throw err;
    }
  }

  async deleteInteraction(storyId, userId) {
    const where = {
      [FIELDS.STORY_ID]: storyId,
      [FIELDS.USER_ID]: userId,
    };

    try {
      const data = await this.collection.deleteOne(where);
      return data;
    } catch (err) {
      throw err;
    }
  }

  async getStoriesWithViewersCount(userId) {
    const pipeline = [
      {
        $match: { [FIELDS.USER_ID]: userId },
      },
      {
        $group: {
          _id: `$${FIELDS.STORY_ID}`,
          count: { $sum: 1 },
        },
      },
    ];

    try {
      const data = await this.collection.aggregate(pipeline).toArray();
      return data;
    } catch (err) {
      throw err;
    }
  }
}

module.exports = {
  instance: new StoriesInteraction(),
  FIELDS
};
