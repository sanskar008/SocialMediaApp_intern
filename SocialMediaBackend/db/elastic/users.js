const { ElasticSearchDB } = require("./db");
const indexName = "users";

const FIELDS = {
  ID: "id",
  PROFILE_PIC: "profilePic",
  STATUS: "status",
  NAME: "name",
  MOBILE: "mobileNumber",
  COUNTRY_CODE: "countryCode",
  EMAIL: "email",
  CREATED_AT: "createdAt",
  NICKNAME: "nickName",
  PASSWORD: "password",
  FCM_TOKEN: "fcmToken",
  STATUS_CODE: "statusCode",
  ADDRESS: "address",
};

class Users extends ElasticSearchDB {
  constructor() {
    super();
  }

  async init() {
    try {
      const client = await super.getClient();
      const exists = await client.indices.exists({ index: indexName });
      if (!exists) {
        await client.indices.create({
          index: indexName,
          body: {
            mappings: {
              properties: {
                [FIELDS.ID]: { type: "keyword" },
                [FIELDS.NAME]: { type: "text" },
                [FIELDS.MOBILE]: { type: "text" },
                [FIELDS.COUNTRY_CODE]: { type: "text" },
                [FIELDS.EMAIL]: { type: "text" },
                [FIELDS.CREATED_AT]: { type: "date" },
                [FIELDS.NICKNAME]: { type: "text" },
                [FIELDS.STATUS]: { type: "text" },
                [FIELDS.PROFILE_PIC]: { type: "text" },
              },
            },
          },
        });
      }
    } catch (err) {
      console.error("Error initializing Elasticsearch index:", err.message);
      throw err;
    }
  }

  async addUser(userId, userDetails) {
    const client = await this.getClient();
    try {
        if (!userId || !userDetails) {
            throw new Error("Missing required parameters: userId or userDetails");
        }

        // Remove `_id` field from `userDetails` if it exists
        const { _id, ...filteredDetails } = userDetails;

        await client.index({
            index: indexName,
            id: userId.toString(), // Use userId as the Elasticsearch document ID
            body: {
                ...filteredDetails, // Add the rest of the user details to the document
                createdAt: new Date().toISOString(), // Add a created timestamp
            },
        });

        console.log('User added to Elasticsearch successfully.');
    } catch (err) {
        console.error('Error adding user to Elasticsearch:', err.message);
        throw err;
    }
}


async searchUserByName(searchString, { page = 1, size = 10 } = {}) {
  const client = await this.getClient();
  const from = (page - 1) * size; // Calculate the offset
  try {
    const result = await client.search({
      index: indexName,
      from,
      size,
      body: {
        query: {
          prefix: {
            [FIELDS.NAME]: searchString.toLowerCase(), // Match prefix
          },
        },
      },
    });

    const users = result.hits.hits.map((hit) => ({
      id: hit._id,
      ...hit._source,
    }));

    return {
      total: result.hits.total.value,
      users,
    };
  } catch (err) {
    console.error('Error searching for usernames in Elasticsearch:', err.message);
    throw err;
  }
}


  async getAllUsers({ page = 1, size = 10 } = {}) {
    const client = await this.getClient();
    const from = (page - 1) * size; // Calculate the offset
    try {
        const result = await client.search({
            index: indexName,
            from,
            size,
            body: {
                query: {
                    match_all: {}, // Fetch all documents
                },
            },
        });

        const users = result.hits.hits.map((hit) => ({
            id: hit._id,
            ...hit._source,
        }));

        return {
            total: result.hits.total.value,
            users,
        };
    } catch (err) {
        console.error('Error fetching all users from Elasticsearch:', err.message);
        throw err;
    }
  }
  async updateUser(userId, updateDetails) {
    const client = await this.getClient();
    try {
      if (!userId || !updateDetails) {
        throw new Error("Missing required parameters: userId or updateDetails");
      }

      const response = await client.update({
        index: indexName,
        id: userId.toString(),
        body: {
          doc: {
            ...updateDetails,
            updatedAt: new Date().toISOString(),
          },
        },
      });

      console.log(`User with ID ${userId} updated successfully.`);
      return response;
    } catch (err) {
      console.error(`Error updating user with ID ${userId}:`, err.message);
      throw err;
    }
  }
}

module.exports = {
  instance: new Users(),
  FIELDS,
};
