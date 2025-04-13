const { MongoDB } = require("./db");
const collectionName = "reactions";
const async = require("async");

const FIELDS = {
  ID: "_id",
  USER_ID: "user_id",
  TAGS: "tags",
  ENTITY_TYPE: "entity_type",
  ENTITY_ID: "entity_id",
  REACTION_TYPE: "reaction_type",
  CREATED_AT: "created_at",
};

class Reactions extends MongoDB {
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
  async addReaction(reaction) {
    const query = {
      [FIELDS.USER_ID]: reaction[FIELDS.USER_ID],
      [FIELDS.ENTITY_TYPE]: reaction[FIELDS.ENTITY_TYPE],
      [FIELDS.ENTITY_ID]: reaction[FIELDS.ENTITY_ID],
    };
    const update = {
      $set: {
        [FIELDS.REACTION_TYPE]: reaction[FIELDS.REACTION_TYPE],
        [FIELDS.CREATED_AT]: new Date(),
      },
    };
    const options = { upsert: true };

    try {
      const data = await this.collection.updateOne(query, update, options);
      data.originalData = reaction;
      if (data.upsertedId) {
        // If it's an insert (new document), return the upsertedId
        return data.upsertedId.toString();
      } else {
        // If it's an update, find the existing _id
        const existingDoc = await this.collection.findOne(query, { projection: { _id: 1 } });
        return existingDoc ? existingDoc._id.toString() : null;
      }
    } catch (err) {
      return Promise.reject(err);
    }
  }

  async getReactionsByEntity(entityId, entityType) {
    const query = {
        [FIELDS.ENTITY_ID]: entityId,
        [FIELDS.ENTITY_TYPE]: entityType
    };

    try {
        const data = await this.collection.aggregate([
            { $match: query },
            {
                $group: {
                    _id: `$${FIELDS.REACTION_TYPE}`, // Group by reaction type
                    count: { $sum: 1 }, // Count reactions per type
                    users: { $push: "$user_id" } // Store users who reacted
                }
            }
        ]).toArray();

        return data.reduce((acc, item) => {
            acc[item._id] = {
                count: item.count,
                users: item.users
            };
            return acc;
        }, {});
    } catch (err) {
        console.error("Error fetching reactions by entity:", err);
        return Promise.reject(new Error("Failed to fetch reactions"));
    }
}

async getUserReactionOnPost(userId, postId) {
  const query = {
      [FIELDS.USER_ID]: String(userId),
      [FIELDS.ENTITY_ID]: String(postId),
  };

  try {
      return await this.collection.findOne(query); // Returns null if no reaction exists
  } catch (err) {
      console.error("Error fetching user reaction:", err);
      return null;
  }
}



  async deleteReaction(reaction) {
    const query = {
      [FIELDS.USER_ID]: reaction[FIELDS.USER_ID],
      [FIELDS.ENTITY_TYPE]: reaction[FIELDS.ENTITY_TYPE],
      [FIELDS.ENTITY_ID]: reaction[FIELDS.ENTITY_ID],
    };

    try {
      const data = await this.collection.deleteOne(query);
      return data;
    } catch (err) {
      console.error("Error deleting reaction:", err);
      return Promise.reject(new Error("Failed to delete reaction"));
    }
  }
  async getReactionsByPostId(postIds) {
    const query = {
        [FIELDS.ENTITY_ID]: { $in: postIds },
    };

    try {
        const data = await this.collection.aggregate([
            { $match: query },
            { $group: { _id: `$${FIELDS.ENTITY_ID}`, reactions: { $push: "$$ROOT" } } }
        ]).toArray();
        return data;
    } catch (err) {
        console.error("Error fetching comments by post IDs:", err);
        return Promise.reject(new Error("Failed to fetch comments"));
    }
  }

  // Add these new methods to your reactions class
async getDetailedReactionsByPostId(postIds) {
  const query = {
    [FIELDS.ENTITY_ID]: { $in: postIds },
  };

  try {
    const data = await this.collection.aggregate([
      { $match: query },
      {
        $group: {
          _id: {
            entityId: `$${FIELDS.ENTITY_ID}`,
            type: `$${FIELDS.REACTION_TYPE}`
          },
          count: { $sum: 1 }
        }
      },
      {
        $group: {
          _id: "$_id.entityId",
          total: { $sum: "$count" },
          types: {
            $push: {
              type: "$_id.type",
              count: "$count"
            }
          }
        }
      }
    ]).toArray();

    // Convert to a more usable format
    const result = {};
    data.forEach(item => {
      const typeMap = {};
      item.types.forEach(type => {
        typeMap[type.type] = type.count;
      });
      
      result[item._id] = {
        total: item.total,
        types: typeMap
      };
    });

    // For single postId requests, return just the data for that post
    if (postIds.length === 1) {
      return result[postIds[0]] || { total: 0, types: {} };
    }

    return result;
  } catch (err) {
    console.error("Error fetching detailed reactions:", err);
    return Promise.reject(new Error("Failed to fetch detailed reactions"));
  }
}

async getUserReactionsOnPosts(userId, postIds) {
  const query = {
    [FIELDS.USER_ID]: String(userId),
    [FIELDS.ENTITY_ID]: { $in: postIds },
  };

  try {
    return await this.collection.find(query).toArray();
  } catch (err) {
    console.error("Error fetching user reactions:", err);
    return [];
  }
}

  async getReactionCountByPostId(postIds) {
    const query = {
        [FIELDS.ENTITY_ID]: { $in: postIds },
    };

    try {
        const data = await this.collection.aggregate([
            { $match: query },
            {
                $group: {
                    _id: `$${FIELDS.ENTITY_ID}`, // Group by entity_id (postId)
                    count: { $sum: 1 }, // Count the number of reactions
                },
            },
        ]).toArray();

        if (postIds.length === 1) {
            return data[0]?.count || 0; 
        }

        return data.reduce((acc, item) => {
            acc[item._id] = item.count;
            return acc;
        }, {});
    } catch (err) {
        console.error("Error fetching reaction count by post IDs:", err);
        return Promise.reject(new Error("Failed to fetch reaction counts"));
    }
}


}

module.exports = {
  instance: new Reactions(),
  FIELDS,
};
