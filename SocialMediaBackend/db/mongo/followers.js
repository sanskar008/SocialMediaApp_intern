const { MongoDB } = require("./db");
const collectionName = "followers";
const async = require("async");

const FIELDS = {
  ID: "_id",
  SENT_BY: "sent_by",
  SENT_TO: "sent_to",
  STATUS: "status",
  CREATED_AT: "created_at",
  UPDATED_AT: "updated_at",
};

class Followers extends MongoDB {
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

  async saveRequest(params) {
    const { sentBy, sentTo } = params;
    const insert = {
      [FIELDS.SENT_BY]: sentBy,
      [FIELDS.SENT_TO]: sentTo,
      [FIELDS.STATUS]: 0,
      [FIELDS.CREATED_AT]: new Date(),
      [FIELDS.UPDATED_AT]: new Date(),
    };

    try {
      const data = await this.collection.insertOne(insert);
      data.originalData = insert;
      return data;
    } catch (err) {
      throw err;
    }
  }
  async acceptFollowRequest(params) {
    const { sentBy, sentTo } = params;
    const where = {
      [FIELDS.SENT_BY]: sentBy,
      [FIELDS.SENT_TO]: sentTo,
      [FIELDS.STATUS]: 0,
    };

    const update = {
      $set: {
        [FIELDS.STATUS]: 1,
        [FIELDS.UPDATED_AT]: new Date(),
      },
    };

    const options = {
      returnOriginal: false,
    };

    try {
      const data = await this.collection.findOneAndUpdate(
        where,
        update,
        options
      );
      return data;
    } catch (err) {
      throw err;
    }
  }

  async requestsCount(userId) {
    const where = {
      [FIELDS.SENT_TO]: userId,
      [FIELDS.STATUS]: 0,
    };

    try {
      const data = await this.collection.countDocuments(where);
      return data;
    } catch (err) {
      throw err;
    }
  }

  async requests(params) {
    const { userId, page, limit } = params;
    const skip = (page - 1) * limit;
    const where = {
      [FIELDS.SENT_TO]: userId,
      [FIELDS.STATUS]: 0,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .skip(skip)
        .limit(limit)
        .toArray();
      return data;
    } catch (err) {
      throw err;
    }
  }

  async followingsCount(userId) {
    const where = {
      [FIELDS.SENT_BY]: userId,
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection.countDocuments(where);
      return data;
    } catch (err) {
      throw err;
    }
  }

  async followersCount(userId) {
    const where = {
      [FIELDS.SENT_TO]: userId,
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection.countDocuments(where);
      return data;
    } catch (err) {
      throw err;
    }
  }

  async getFollowings(userId) {
    const where = {
      [FIELDS.SENT_BY]: userId,
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      const response = data && data.length ? data : [];
      return response;
    } catch (err) {
      throw err;
    }
  }

  async getFollowers(userId) {
    const where = {
      [FIELDS.SENT_TO]: userId,
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      const response = data && data.length ? data : [];
      return response;
    } catch (err) {
      throw err;
    }
  }
  async removeRequest(params, status = null) {
    const { sentBy, sentTo } = params;

    const body = {
      [FIELDS.SENT_BY]: sentBy,
      [FIELDS.SENT_TO]: sentTo,
      [FIELDS.STATUS]: 0
    };
    if (status) {
      body[FIELDS.STATUS] = status
    }
    try {
      const data = await this.collection.findOneAndDelete(body);
      return data;
    } catch (err) {
      throw err;
    }
  }

  async acceptRequest(params) {
    const { sentBy, sentTo } = params;
    const where = {
      [FIELDS.SENT_BY]: sentBy,
      [FIELDS.SENT_TO]: sentTo,
    };

    const options = {
      returnOriginal: false,
    };

    try {
      const data = await this.collection.findOneAndUpdate(
        where,
        { $set: { [FIELDS.STATUS]: 1 } },
        options
      );
      return data;
    } catch (err) {
      throw err;
    }
  }

  async requestsPendingStatus(userId, userIDs) {
    const where = {
      [FIELDS.SENT_TO]: userId,
      [FIELDS.SENT_BY]: { $in: userIDs },
      [FIELDS.STATUS]: 0,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      const response =
        data && data.length ? data.map((user) => user[FIELDS.SENT_BY]) : [];
      return response;
    } catch (err) {
      throw err;
    }
  }

  async requestsSentStatus(userId, userIDs) {
    const where = {
      [FIELDS.SENT_BY]: userId,
      [FIELDS.SENT_TO]: { $in: userIDs },
      [FIELDS.STATUS]: 0,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      const response =
        data && data.length ? data.map((user) => user[FIELDS.SENT_TO]) : [];
      return response;
    } catch (err) {
      throw err;
    }
  }
  async isRelated(userId, userIDs, status = null) {
    const where = {
      [FIELDS.SENT_BY]: userId,
      [FIELDS.SENT_TO]: { $in: userIDs },
    };

    if (status !== null) {
      where[FIELDS.STATUS] = status;
    } else {
      where.$or = [{ [FIELDS.STATUS]: 0 }, { [FIELDS.STATUS]: 1 }];
    }

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      const response =
        data && data.length ? data.map((user) => user[FIELDS.SENT_TO]) : [];
      return response;
    } catch (err) {
      throw err;
    }
  }

  async requestsSentList(userId) {
    const where = {
      [FIELDS.SENT_BY]: userId,
      [FIELDS.STATUS]: 0,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      const response =
        data && data.length ? data.map((user) => user[FIELDS.SENT_TO]) : [];
      return response;
    } catch (err) {
      throw err;
    }
  }

  async isFollowing(userId, followingIds) {
    const where = {
      [FIELDS.SENT_BY]: userId,
      [FIELDS.SENT_TO]: { $in: followingIds },
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      return data && data.length
        ? data.map((user) => user[FIELDS.SENT_TO])
        : [];
    } catch (err) {
      throw err;
    }
  }

  async isFollower(followingIds, selfId) {
    const where = {
      [FIELDS.SENT_BY]: { $in: followingIds },
      [FIELDS.SENT_TO]: selfId,
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection
        .find(where)
        .sort({ _id: -1 })
        .toArray();
      return data && data.length
        ? data.map((user) => user[FIELDS.SENT_BY])
        : [];
    } catch (err) {
      throw err;
    }
  }

  async removeFollower(follower, following) {
    const where = {
      [FIELDS.SENT_BY]: follower,
      [FIELDS.SENT_TO]: following,
      [FIELDS.STATUS]: 1,
    };

    try {
      const data = await this.collection.findOneAndDelete(where);
      return !!data.value;
    } catch (err) {
      throw err;
    }
  }
}

module.exports = {
  instance: new Followers(),
  FIELDS,
};
