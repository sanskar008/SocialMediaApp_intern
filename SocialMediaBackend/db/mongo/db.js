require('dotenv').config()
const { MongoClient, ObjectId} = require("mongodb");
const host = process.env.MONGO_HOST || "localhost";
const dbName = process.env.MONGO_DB_NAME || "social-Media-BE";
const user = process.env.MONGO_USER;
const pass = process.env.MONGO_PASS;
const port = process.env.MONGO_PORT || "27017"

let DBInstance;
class MongoDB {
  constructor(){
    this.db = DBInstance;
    this.dbName = dbName;
    this.dbReady = false;
  }

  getDBName() {
    return this.dbName;
  }

  async getDBInstance() {
    if(!DBInstance) return this.connect();
    return DBInstance;
  }

  async connect() {
    let uri = `mongodb://localhost:27017/${dbName}`
    if (host == "aryan") uri = process.env.aryan_uri;
    if (DBInstance) return Promise.resolve(DBInstance); // Reuse existing connection

const client = new MongoClient(uri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

return client
    .connect()
    .then(() => {
        console.log('Connected to MongoDB');
        DBInstance = client.db(dbName);
        return DBInstance;
    })
    .catch((err) => {
        console.error('Error connecting to MongoDB:', err.message);
        throw err; // Reject the promise with the error
    });

  }

  getNewObjectId() {
    const objectId = new ObjectId();
    return objectId.toHexString();
  }

  getStringFromObjectId(objectId){
    return objectId.toHexString()
  }

  getObjectIdFromString(stringId) {
  return new ObjectId(stringId);
  }
}

module.exports = {
  MongoDB,
  instance: new MongoDB()
};