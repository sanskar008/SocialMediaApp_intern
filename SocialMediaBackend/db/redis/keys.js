const REDIS_KEYS = {

    OTP_DATA: (countryCode,mobile) => {
        return `OTP_DATA:${countryCode}:${mobile}`
    },

    REQUEST_COUNT : (phoneNumber,countryCode) => {
        return `REQUEST_COUNT:${countryCode}:${phoneNumber}`
    },

    USERS_DATA : (userId) => {
        return `USERS_DATA:${userId}`
    },

    SOCKET_TOKEN: (userId) => {
        return `SOCKET_TOKEN:${userId}`
    },

    SSO_TOKEN: (userId) => {
        return `SSO:${userId}`;
    },

    ROOM_PARTICIPANTS_ONLINE: (roomId) => {
        return `ROOM_PARTICIPANTS_ONLINE:${roomId}`; // Stores which user is associated with which socketId
    },

    USER_FCM_TOKENS: (userId) => {
        return `USER_FCM_TOKENS:${userId}`; // Stores FCM tokens for the user
    },

    USER_SOCKET_ROOMS: (userId) => {
        return `USER_SOCKET_ROOMS:${userId}`; // Stores rooms a user is part of for socket communication
    }
}


module.exports = REDIS_KEYS