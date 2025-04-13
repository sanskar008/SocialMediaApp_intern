const { MongoDB } = require("./db");
const collectionName = "feeds";
const moment = require("moment");
const { ObjectId } = require("mongodb");

const CACHED_FEEDS = {}

const FIELDS = {
    ID: '_id',
    STATUS: 'status',
    AUTHOR: 'author',
    CONTENT_TYPE: 'content_type',
    CREATED_AT: 'createdAt',
    UPDATED_AT: 'updatedAt',
    TAGGED_USERS: 'taggedUsers',
    MENTIONED_USERS: 'mentionedUsers',
    COMMENTS_COUNT: 'commentsCount',
    PRIVACY: 'privacy',
    HIDE_FROM: 'hideFrom',
    PRIVATE_TO: 'privateTo',
    WHO_CAN_COMMENT: 'whoCanComment',
    DATA: 'data',
    WEEK_INDEX: 'weekIndex',
    FEED_ID: 'feedId'
  }
  
const FIELDS_VALUES ={
    [FIELDS.STATUS]:{
      'LIVE' :1,
      'DELETED':0
    },

    [FIELDS.WHO_CAN_COMMENT]: {
        'EVERYONE' : 1,
        'NO_ONE' : 0
    },

    [FIELDS.PRIVACY] : {
        'FRIENDS': 1,
        'NO_ONE' : 0,
        'PUBLIC': 2
    },

    [FIELDS.CONTENT_TYPE]: {
        TEXT: 'text',
        IMAGE: 'image',
        VIDEO: 'video',
      },
}




const forDate = async(date) => {
  if (!date || typeof date !== 'string') {
    throw new TypeError('Invalid param date');
  }
  if (!CACHED_FEEDS[date]) {
    const weekId = buildWeekIdForDate(date);
    const feedInstance = new Feeds(`feeds-${weekId}`, date);
    await feedInstance.init()
    CACHED_FEEDS[date] = feedInstance;
  }
  return CACHED_FEEDS[date];
}

const forId = async(feedId) => {
  if (!feedId || feedId.indexOf(':') <= -1) {
    throw new TypeError('Invalid param feedId');
  }
  const [_id, date] = feedId.split(":");
  if (!CACHED_FEEDS[date]) {
    // TODO: check if index exists
    const weekId = buildWeekIdForDate(date);
    const feedInstance = new Feeds(`feeds-${weekId}`, date);
    await feedInstance.init()
    CACHED_FEEDS[date] = feedInstance;
  }
  return CACHED_FEEDS[date];
};

const buildWeekIdForDate = (date) => {
  if(!date) {
    throw new TypeError('Invalid argument date');
  }
  const _moment = moment(date, 'YYYY-MM-DD', true);
  if (!_moment.isValid()) {
    throw new TypeError('Invalid date format. Expected YYYY-MM-DD');
  }
  let year = moment(date).format('YYYY');
  let month = moment(date).format('MM');
  let week = moment(date).format('WW');
  if(month === "12" && week === 1){
    year += 1;
  }
  return `${year}-${week}`;
};

const getNextWeekIndexName = () => `feeds-${buildWeekIdForDate(moment().add(1, 'week').format('YYYY-MM-DD'))}`;

class Feeds extends MongoDB {

  constructor(index, date) {
    super();
    this.index = index;
    this.date = date;
  }
  
  async init() {
    if (!this.collection) {
      const db = await super.getDBInstance();
      this.collection = db.collection(collectionName); // Ensure the collection is tied to the index
    }
  }

  getCollectionInstance() {
    return this.collection;
  }
  
  async getAllIndices() {
    try {
      const indices = await this.collection.indexes();
      return indices;
    } catch (err) {
      console.error("Error fetching indices:", err);
      throw err;
    }
  }
  async createIndex(indexObj) {
    try {
      const indexDefinition = { [FIELDS.WEEK_INDEX]: 1 }; 
    await this.collection.createIndex(indexDefinition, { name: indexObj });
    } catch (err) {
      console.error("Error creating index:", err);
      throw err;
    }
  }



  // Query to fetch a post by post_id
  async getPostById(postId) {
    try {
      const post = await this.collection.find({
        [FIELDS.WEEK_INDEX]: this.index,
        [FIELDS.FEED_ID]: postId, // Query by the unique post ID
      }).toArray(); // Convert to array
  
      return post.length > 0 ? post[0] : null; // Return the first post or null if not found
    } catch (err) {
      console.error("Error fetching post by ID:", err);
      return null;
    }
  }
  
  async getPostsByWeek() {
    try {
      const posts = await this.collection.find({
        [FIELDS.WEEK_INDEX]: this.index,
        [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].LIVE
      }).toArray();
      return posts; // Returns posts for the specified week
    } catch (err) {
      console.error("Error fetching posts by week:", err);
      throw err;
    }
  }
    

  // Query to update a post by post_id
  async updatePostById(postId, updateObj) {
    try {
      const result = await this.collection.findOneAndUpdate(
        { [FIELDS.FEED_ID]: new ObjectId(postId) },
        { $set: updateObj },
        { returnDocument: "after" }
      );
      return result; // Returns the updated post if successful, otherwise null
    } catch (err) {
      console.error("Error updating post:", err);
      throw err;
    }
  }

  // Query to delete a post by post_id
  async deletePostById(postId) {
    try {
      const result = await this.collection.findOneAndUpdate(
        { [FIELDS.FEED_ID]: postId },
        {
          $set: {
            [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].DELETED,
            [FIELDS.UPDATED_AT]: new Date()
          }
        },
        { returnDocument: "after" }
      );
      return !!result._id; // Returns true if the document was updated, false otherwise
    } catch (err) {
      console.error("Error updating post status to deleted:", err);
      throw err;
    }
  }
  

  // Query to get all posts of a user by userId
  async getAllPostsByUserId(userId) {
    try {
      const posts = await this.collection.find({
        [FIELDS.AUTHOR]: userId,
        [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].LIVE
      }).toArray();
      return posts; // Returns all posts of the user
    } catch (err) {
      console.error("Error fetching posts by user ID:", err);
      throw err;
    }
  }

  async getPostsByUserIds(userIds) {
    try {
      const posts = await this.collection
        .find({
          [FIELDS.AUTHOR]: { $in: userIds },
          [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].LIVE
        })
        .sort({ [FIELDS.CREATED_AT]: -1 }) // Sort by creation time (most recent first)
        .toArray();
  
      // Group posts by userId
      const groupedPosts = userIds.map(userId => ({
        userId,
        posts: posts.filter(post => post[FIELDS.AUTHOR] === userId),
      }));
  
      return groupedPosts;
    } catch (err) {
      console.error('Error fetching posts by user IDs:', err);
      throw err;
    }
  }
  
  async getDeletedPostsByWeek() {
    try {
      const posts = await this.collection
        .find({ 
          [FIELDS.WEEK_INDEX]: this.index,
          [FIELDS.STATUS]: FIELDS_VALUES[FIELDS.STATUS].DELETED
        })
        .toArray();
      return posts; // Returns deleted posts for the specified week
    } catch (err) {
      console.error("Error fetching deleted posts by week:", err);
      throw err;
    }
  }
  
  createPost(data) {
    return new Promise(async (resolve, reject) => {
      // Handle string inputs for privateTo and hideFrom
      if (typeof data[FIELDS.PRIVATE_TO] === 'string') {
        data[FIELDS.PRIVATE_TO] = data[FIELDS.PRIVATE_TO].split(',').map(id => id.trim());
      }
      if (typeof data[FIELDS.HIDE_FROM] === 'string') {
        data[FIELDS.HIDE_FROM] = data[FIELDS.HIDE_FROM].split(',').map(id => id.trim());
      }

      data[FIELDS.WEEK_INDEX] = this.index;
      const newObjectId = new ObjectId();
      data[FIELDS.ID] = newObjectId;
      data[FIELDS.FEED_ID] = `${newObjectId}:${data[FIELDS.FEED_ID]}`;
      
      this.collection.insertOne(data)
        .then(result => {result.original = data; resolve(result);})
        .catch(error => reject(error));
    });
  }
  


  

  
}


module.exports = {
  Feeds,
  FIELDS,
  instance : new Feeds(null,null),
  FIELDS_VALUES,
  getNextWeekIndexName,
  forDate,
  forId
};