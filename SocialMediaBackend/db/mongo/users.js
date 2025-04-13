const { MongoDB } = require("./db");
const collectionName = "users";
const moment = require("moment");


const FIELDS = {
    ID: '_id',
    PROFILE_PIC: 'profilePic',
    STATUS: 'status',
    NAME: 'name',
    MOBILE: 'mobileNumber',
    COUNTRY_CODE: 'countryCode',
    EMAIL: 'email',
    CREATED_AT: 'createdAt',
    NICKNAME: 'nickName',
    PASSWORD:'password',
    FCM_TOKEN: 'fcmToken',
    STATUS_CODE : 'statusCode',
    ADDRESS : 'address',
    PRIVACY_LEVEL : 'privacyLevel',
    IS_BOT : 'isBot',
    AVATAR : 'avatar',
    INTERESTS: 'interests',
    COMMUNITIES: 'communities',
    PUBLIC: 'public'
  }
  
const FIELD_VALUES = {
  [FIELDS.STATUS_CODE] : {
    ON_BOARDED : 0,   // SIRF AYA HAI ABHI TK
    PASSWORD_SET : 1, // PASSWORD SET KRLIYA USNE APNA
    PROFILE_SET : 2   // SARI PROFILE DETIALS BHI DALDI HAI
  },
  [FIELDS.PRIVACY_LEVEL] : {
      OPEN : 0,
      CLOSED : 1
  }
}

class Users extends MongoDB {
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

  async getUserDetailsFromId(userId) {
    try {
      // Convert the userId to ObjectId as MongoDB uses ObjectId for the _id field
      const objectId = super.getObjectIdFromString(userId);

      // Perform the query to find the user by ObjectId
      const userDetails = await this.collection.findOne({ _id: objectId });

      if (!userDetails) {
        return null; // If no user is found, return null
      }

      const effectiveProfilePic =
      (!userDetails.profilePic || userDetails.privacyLevel.toString() === '1') ?
      userDetails.avatar
      : userDetails.profilePic;

      // Adjust the `name` field based on privacyLevel
      const displayName =
      (userDetails.privacyLevel)?.toString() === '0'
      ? userDetails.name
      : userDetails.nickName;

      return {
        ...userDetails,
        profilePic : effectiveProfilePic,
        name: displayName || userDetails.name || null,
      };
    } catch (err) {
      console.error("Error fetching user by ID:", err.message);
      throw err; // Re-throw the error for the caller to handle
    }
  }

  async joinCommunity(userId, params) {
    const { communityId, action } = params;
    try {
      // Convert the userId to ObjectId as MongoDB uses ObjectId for the _id field
      const objectId = super.getObjectIdFromString(userId);

      // Determine the update operation based on the action
      let updateOperation;
      if (action === 'join') {
        updateOperation = { $addToSet: { [FIELDS.COMMUNITIES]: communityId } }; // Add communityId to the array
      } else if (action === 'remove') {
        updateOperation = { $pull: { [FIELDS.COMMUNITIES]: communityId } }; // Remove communityId from the array
      } else {
        throw new Error("Invalid action. Use 'join' or 'remove'.");
      }

      // Perform the update operation
      const result = await this.collection.updateOne(
        { _id: objectId },
        updateOperation
      );

      if (result.matchedCount === 0) {
        throw new Error("User not found");
      }

      return result; // Return the result of the update operation
    } catch (err) {
      console.error("Error updating user communities:", err.message);
      throw err; // Re-throw the error for the caller to handle
    }
  }

  async getUserDetailsFromIds(userIds) {
    try {
        // Convert all userIds to ObjectId as MongoDB uses ObjectId for the _id field
        const objectIds = userIds.map(userId => super.getObjectIdFromString(userId));

        // Perform a query to find all users by their ObjectIds
        const users = await this.collection.find({ _id: { $in: objectIds } }).toArray();

        // Create a map of userId to user details for quick lookup
        const userMap = users.reduce((acc, user) => {
            const effectiveProfilePic =
            (!user.profilePic || user.privacyLevel.toString() === '1') ?
            user.avatar
            : user.profilePic;

            const displayName =
              (user.privacyLevel).toString() === '0'
              ? user.name
              : user.nickName;

            acc[user._id.toString()] = {
              ...user,
              profilePic: effectiveProfilePic,
              name: displayName || user.name || null,
            };
            return acc;
        }, {});

        // Return users in the same order as the provided userIds
        return userIds.map(userId => userMap[userId.toString()] || null);
    } catch (err) {
        console.error("Error fetching users by IDs:", err.message);
        throw err; // Re-throw the error for the caller to handle
    }
}

async getUserCommunities(userId) {
  try {
    const objectId = super.getObjectIdFromString(userId);
    const user = await this.collection.findOne(
      { _id: objectId },
      { projection: { [FIELDS.COMMUNITIES]: 1 } }
    );
    return user?.communities || [];
  } catch (err) {
    console.error("Error fetching user communities:", err.message);
    throw err;
  }
}
  
  async getUserDetailsFromMobile(mobile, countryCode) { //actually send detials
    try {
        // Build the query
        const where = {
            [FIELDS.COUNTRY_CODE]: countryCode,
            [FIELDS.MOBILE]: mobile,
        };

        // Perform the query using await
        const data = await this.collection.findOne(where);

        if (!data) {
            return null
            // throw new Error("User not found"); // Handle case where user doesn't exist
        }

        const effectiveProfilePic =
        (!data.profilePic || data.privacyLevel.toString() === '1') ?
        data.avatar
        : data.profilePic;

            // Adjust the name based on privacyLevel
        const displayName =
          (data.privacyLevel).toString() === '0'
          ? data.name
          : data.nickName;

        return {
          ...data,
          profilePic: effectiveProfilePic,
          name: displayName || data.name || null,
        };
    } catch (err) {
        console.error("Error fetching user by mobile:", err.message);
        throw err; // Re-throw the error for the caller to handle
    }
    }
    async getUsers(page = 1, limit = 10) {
      try {
        // Ensure numeric values
        const pageNum = parseInt(page, 10);
        const limitNum = parseInt(limit, 10);
  
        // Ensure collection initialized
        if (!this.collection) {
          const db = await super.getDBInstance();
          this.collection = db.collection(collectionName);
        }
        const total = await this.collection.countDocuments({});
        // Pagination ke sath query (koi filter nahi lagayenge)
        const usersList = await this.collection.find({})
          .skip((pageNum - 1) * limitNum)
          .limit(limitNum)
          .toArray();
        return {total ,users:usersList};
      } catch (err) {
        console.error("Error in getUsers function:", err.message);
        throw err;
      }
    }
    
  // Function to fetch user showing details
async getUserShowingDetails(userIds) {
  try {
    // Convert all userIds to ObjectId as MongoDB uses ObjectId for the _id field
    const objectIds = userIds.map(userId => super.getObjectIdFromString(userId));

    // Query users by their ObjectIds
    const users = await this.collection.find(
        { [FIELDS.ID]: { $in: objectIds } },
        {
          projection: {
            [FIELDS.ID]: 1,
            [FIELDS.PROFILE_PIC]: 1,
            [FIELDS.NAME]: 1,
            [FIELDS.NICKNAME]: 1,
            [FIELDS.PRIVACY_LEVEL]: 1,
            [FIELDS.AVATAR]: 1,
          },
        }
      )
      .toArray();

    // Create a map of userId to user details for quick lookup
    const userMap = users.reduce((acc, user) => {
      const effectiveProfilePic =
      (!user.profilePic || user.privacyLevel.toString() === '1') ?
      user.avatar
      : user.profilePic;

      const displayName = (user?.privacyLevel).toString() === '0'
          ? user?.name || null
          : user?.nickName || null;

      acc[user._id.toString()] = {
        userId: user._id.toString(),
        profilePic: effectiveProfilePic || null,
        name: displayName
      };
      return acc;
    }, {});

    // Return users in the same order as the provided userIds
    return userIds.map(userId => userMap[userId.toString()] || null);
  } catch (err) {
    console.error("Error fetching user showing details:", err.message);
    throw err; // Re-throw the error for the caller to handle
  }
}

  async checkIfUserExists(phoneNumber, countryCode) {
    try {
      const where = {
        [FIELDS.COUNTRY_CODE]: countryCode,
        [FIELDS.MOBILE]: phoneNumber,
      };
  
      // Use the promise-based version of findOne
      const data = await this.collection.findOne(where);
      return data; // Resolve with the data
    } catch (err) {
      console.error("Error checking user existence:", err); // Optional logging
      return err; // Re-throw the error for caller to handle
    }
  }

  async createUser(data) {
    try {
        const result = await this.collection.insertOne(data);

        return result.insertedId; // Return only the inserted ID
    } catch (err) {
        console.error("Error checking user existence:", err); // Optional logging
        throw err; // Re-throw the error for caller to handle
    }
  }

  async checkBot() {
    try {
      const where = {
        [FIELDS.IS_BOT]: true,
      };

      const data = await this.collection.findOne(where);
      return data;
    } catch (err) {
      console.error("Error checking bot existence:", err);
      return err;
    }
  }

  async updateUser(userId, updateObj) {
    try {
        // Convert toString ID to ObjectId
        const objectId = super.getObjectIdFromString(userId);
        // console.log(objectId);

        // Perform the update operation
        const result = await this.collection.findOneAndUpdate(
            { _id: objectId },
            { $set: updateObj },
            { returnDocument: "after" } // Use "after" to get the updated document
        );

        if (!result) {
            throw new Error("User not found");
        }

        return result; // Return the updated document
    } catch (err) {
        console.error("Error updating user:", err);
        return err // Rethrow the error for the caller
    }


}

async getUsersWithSharedInterests(currentUserId, interests, limit = 10, page = 1) {
  try {
    const objectId = super.getObjectIdFromString(currentUserId);

    const users = await this.collection
      .aggregate([
        { $match: { _id: { $ne: objectId }, interests: { $elemMatch: { $regex: new RegExp(`^(${interests.join("|")})$`, "i") } } } }, 
        {
          $addFields: {
            matchScore: {
              $size: { $setIntersection: [{ $map: { input: "$interests", as: "int", in: { $toLower: "$$int" } } },
              interests] }
            }
          }
        },
        { $sort: { matchScore: -1 } }, // Sort by match score (descending)
        { $skip: (page - 1) * limit }, // Pagination: Skip previous pages
        { $limit: limit }, // Limit results
        {
          $project: {
            _id: 1,
            name: 1,
            profilePic: 1,
            interests: 1,
            privacyLevel: 1,
            avatar: 1, 
            nickName: 1,
            matchScore: 1
          }
        }
      ])
      .toArray();

    // Mapping to add effective profilePic and name based on privacyLevel
    const updatedUsers = users.map(user => {
      const effectiveProfilePic = (!user.profilePic || user.privacyLevel.toString() === '1') 
        ? user.avatar 
        : user.profilePic;
      const effectiveName = (user.privacyLevel.toString() === '0') 
        ? user.name 
        : user.nickName;
      return {
        ...user,
        profilePic: effectiveProfilePic,
        name: effectiveName
      };
    });

    return updatedUsers;
  } catch (err) {
    console.error("Error fetching users by shared interests:", err);
    throw err;
  }
}

async findUsersByInterest(currentUserId, messageInterest) {
  try {
    const objectId = super.getObjectIdFromString(currentUserId);

    // Step 1: Parse the message interests by splitting on comma
    const interestsToMatch = messageInterest
      .split(',')
      .map(interest => interest.trim().toLowerCase())
      .filter(interest => interest.length > 0);

    if (interestsToMatch.length === 0) {
      console.warn(`⚠ No valid interests provided in message: ${messageInterest}`);
      return [];
    }

    // Step 2: Find users who have any of these interests (excluding current user)
    const users = await this.collection
      .find({
        _id: { $ne: objectId }, // Exclude the current user
        interests: { $elemMatch: { $regex: new RegExp(`^(${interestsToMatch.join("|")})$`, "i") } }
      })
      .project({
        _id: 1,
        name: 1,
        profilePic: 1,
        interests: 1,
        privacyLevel: 1,
        avatar: 1,
        nickName: 1
      })
      .toArray();

    if (users.length === 0) {
      console.warn(`⚠ No users found with interests: ${interestsToMatch.join(', ')}`);
      return [];
    }

    // Step 3: Map and rank users based on matching interests
    const rankedUsers = users
      .map(user => {
        const matchingInterests = user.interests.filter(interest =>
          interestsToMatch.includes(interest.toLowerCase())
        );
        
        // Apply privacy settings for profile picture and name
        const effectiveProfilePic = (!user.profilePic || user.privacyLevel?.toString() === '1') 
          ? user.avatar 
          : user.profilePic;
          
        const effectiveName = (user.privacyLevel?.toString() === '0') 
          ? user.name 
          : user.nickName;

        return {
          ...user,
          profilePic: effectiveProfilePic,
          name: effectiveName || user.name,
          matchingInterestsCount: matchingInterests.length,
          matchingInterests: matchingInterests
        };
      })
      .sort((a, b) => {
        // Sort by the number of matching interests (descending)
        return b.matchingInterestsCount - a.matchingInterestsCount;
      })
      .slice(0, 3); // Return top 3 matches

    return rankedUsers;
  } catch (err) {
    console.error("Error finding users by interests:", err);
    throw err;
  }
}
  async checkAnonymousUsers(userIds) {
    try {
      // Convert all userIds to ObjectId as MongoDB uses ObjectId for the _id field
      const objectIds = userIds.map(userId => super.getObjectIdFromString(userId?.id));

      // Perform a query to find all users by their ObjectIds
      const users = await this.collection.find({ _id: { $in: objectIds } }).toArray();

      // Create an array of booleans indicating whether each user's privacy level is 1
      const privacyArray = users.map(user => user[FIELDS.PRIVACY_LEVEL] == 1);

      return privacyArray;
    } catch (err) {
      console.error("Error checking anonymous users:", err.message);
      throw err; // Re-throw the error for the caller to handle
    }
  }
  // In your users module (e.g. db/mongo/users.js)
async getRandomPublicUserIds(limit = 10) {
  try {
    // Use aggregation with $match and $sample to pick random public users.
    const cursor = await this.collection.aggregate([
      { $match: { [FIELDS.PUBLIC]: 1 } },
      { $sample: { size: limit } },
      { $project: { _id: 1 } }
    ]);
    const results = await cursor.toArray();
    // Map ObjectId's to string if necessary.
    return results.map(user => user._id.toString());
  } catch (err) {
    console.error("Error fetching random public user IDs:", err.message);
    throw err;
  }
}

}

module.exports = {
  instance: new Users(),
  FIELDS,
  FIELD_VALUES,
};
