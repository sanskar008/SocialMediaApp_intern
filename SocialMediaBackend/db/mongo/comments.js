const { ObjectId } = require("mongodb");
const { MongoDB } = require("./db");
const collectionName = "comments";
const async = require("async");

const FIELDS = {
    ID: "_id",
    USER_ID: "user_id",
    PARENT_COMMENT: "parentComment",
    POST_ID: "postId",
    COMMENT: "comment",
    CREATED_AT: "created_at",
};

class Comments extends MongoDB {
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

    async addComment(comment) {
        const newComment = {
            [FIELDS.USER_ID]: comment[FIELDS.USER_ID],
            [FIELDS.PARENT_COMMENT]: comment[FIELDS.PARENT_COMMENT],
            [FIELDS.POST_ID]: comment[FIELDS.POST_ID],
            [FIELDS.COMMENT]: comment[FIELDS.COMMENT],
            [FIELDS.CREATED_AT]: new Date(),
        };

        try {
            const data = await this.collection.insertOne(newComment);
            return data;
        } catch (err) {
            return Promise.reject(err);
        }
    }

    async findCommentsByParentId(parentCommentId) {
        try {
            const query = {
                [FIELDS.PARENT_COMMENT]: parentCommentId
            };
    
            const comments = await this.collection.find(query).toArray();
            return comments;
        } catch (err) {
            console.error("Error fetching child comments:", err);
            throw new Error("Failed to fetch child comments.");
        }
    }
    
    //this will delete both comment as well as its replies
    async deleteComment(commentId) {
        const query = {
            $or: [
                { [FIELDS.ID]: new ObjectId(commentId) },
                { [FIELDS.PARENT_COMMENT]: new ObjectId(commentId) }
            ]
        };

        try {
            const data = await this.collection.deleteOne(query);
            return data;
        } catch (err) {
            console.error("Error deleting comment:", err);
            return Promise.reject(new Error("Failed to delete comment"));
        }
    }

    async findComment(commentId) {
        const where ={
            [FIELDS.ID] : new ObjectId(commentId)
        }

        try {
            const data = await this.collection.find(where).toArray();
            return data;
        } catch (err) {
            throw err;
        }
    }

    
    async getCommentsByPostId(postIds) {
        const query = {
          [FIELDS.POST_ID]: { $in: postIds },
        };
      
        try {
          const data = await this.collection
            .aggregate([
              { $match: query },
              { $sort: { [FIELDS.CREATED_AT]: 1 } }, // Sort by createdAt in ascending order
              { $group: { _id: `$${FIELDS.POST_ID}`, comments: { $push: "$$ROOT" } } },
            ])
            .toArray();
      
          return data;
        } catch (err) {
          console.error("Error fetching comments by post IDs:", err);
          return Promise.reject(new Error("Failed to fetch comments"));
        }
      }
      

async getCommentCountByPostId(postIds) {
    const query = {
        [FIELDS.POST_ID]: { $in: postIds },
    };

    try {
        const data = await this.collection.aggregate([
            { $match: query },
            {
                $group: {
                    _id: `$${FIELDS.POST_ID}`, // Group by postId
                    count: { $sum: 1 }, // Count the number of comments
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
        console.error("Error fetching comment count by post IDs:", err);
        return Promise.reject(new Error("Failed to fetch comment counts"));
    }
}


}

module.exports = {
    instance: new Comments(),
    FIELDS,
};
