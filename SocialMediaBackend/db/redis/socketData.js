const query = require('./query'); // Existing set and get utility functions
const keys = require('./keys');  // Keys to be used for socket data

const socketManager = {};

// Add a socket ID for a user to Redis
socketManager.addSocketId = async (userId, socketId) => {
    return new Promise((resolve, reject) => {
        const key = keys.USER_SOCKET(userId); // Redis key to store user's socket ID
        query.set(key, socketId, (err, result) => {
            if (err) reject(err);
            resolve(result); // Return the result (success/failure)
        });
    });
};

// Get a socket ID for a user from Redis
socketManager.getSocketId = async (userId) => {
    return new Promise((resolve, reject) => {
        const key = keys.USER_SOCKET(userId); // Redis key to retrieve user's socket ID
        query.get(key, (err, result) => {
            if (err) reject(err);
            resolve(result); // Return the socket ID or null if not found
        });
    });
};

// Remove a socket ID when a user disconnects
socketManager.removeSocketId = async (userId) => {
    return new Promise((resolve, reject) => {
        const key = keys.USER_SOCKET(userId); // Redis key to remove user's socket ID
        query.del(key, (err, result) => {
            if (err) reject(err);
            resolve(result); // Return the result (success/failure)
        });
    });
};

// Add a user to a chat room in Redis (track their participation)
socketManager.addUserToRoom = async (userId, roomId) => {
    return new Promise((resolve, reject) => {
        const key = keys.ROOM_PARTICIPANTS_ONLINE(roomId); // Redis key to store participants in a room
        query.sadd(key, userId, (err, result) => {
            if (err) reject(err);
            resolve(result); // Return the result (success/failure)
        });
    });
};

// Remove a user from a chat room in Redis (track their exit from the room)
socketManager.removeUserFromRoom = async (userId, roomId) => {
    return new Promise((resolve, reject) => {
        const key = keys.ROOM_PARTICIPANTS_ONLINE(roomId); // Redis key to store participants in a room
        query.srem(key, userId, (err, result) => {
            if (err) reject(err);
            resolve(result); // Return the result (success/failure)
        });
    });
};

// Get all participants of a room
socketManager.getRoomParticipants = async (roomId) => {
    return new Promise((resolve, reject) => {
        const key = keys.ROOM_PARTICIPANTS_ONLINE(roomId); // Redis key to retrieve participants of a room
        query.smembers(key, (err, result) => {
            if (err) reject(err);
            resolve(result); // Return the list of user IDs participating in the room
        });
    });
};


module.exports = socketManager;
