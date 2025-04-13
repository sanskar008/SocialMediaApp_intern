const client = require('./client');

module.exports = {
    set: async (key, value, cb) => {
        try {
            await client.set(key, value);
            return cb(null,[])
        } catch (err) {
            console.error('Error setting Redis key:', err);
            return cb(err,null)
        }
    },

    setWithExpiry : async (key, value, expiration = 0) => {
        try {
            await client.set(key, value);
            if (expiration) {
                await client.expire(key, expiration);
            }
        } catch (err) {
            console.error('Error setting Redis key:', err);
            throw err;
        }
    },
    get: async (key,cb=()=>{}) => {
        try {
            const value = await client.get(key);
            return cb(null,value);
        } catch (err) {
            console.error('Error getting Redis key:', err);
            return cb(err,null);
        }
    },
    expire: async (key, TTL) => {
        try {
            await client.expire(key,TTL);
        } catch (err) {
            console.error('Error getting TTL for Redis key:', err);
            throw err;
        }
    },

    getTTL: async (key) => {
        try {
            const ttl = await client.ttl(key);
            return ttl;
        } catch (err) {
            console.error('Error getting TTL for Redis key:', err);
            throw err;
        }
    },

    del: async (key, callback) => {
      
        if (client) {
          client.del(key)
            .then(result => callback(null, result))
            .catch(error => callback(error, null));
        } else {
          return callback("error in getting redis client", null);
        }
      },
    
    hget: async (hash, callback) => {
        if (client && hash.key && hash.field) {
          client.hGet(hash.key, hash.field)
            .then(result => callback(null, result))
            .catch(error => callback(error, null));
        } else {
          return callback("error in getting redis client", null);
        }
    },

    hmset: async (key, values, callback) => {
      
        if (client && key && values && Object.keys(values).length > 0) {
          client.hSet(key, values)
            .then(result => callback(null, result))
            .catch(error => callback(error, null));
        } else {
          return callback("error in getting redis client or key/values is invalid", null);
        }
    },

    sadd: async (key, value, cb) => {
        try {
            await client.sAdd(key, value);
            return cb(null, []);
        } catch (err) {
            console.error('Error adding to Redis set:', err);
            return cb(err, null);
        }
    },

    srem: async (key, value, cb) => {
        try {
            await client.sRem(key, value);
            return cb(null, []);
        } catch (err) {
            console.error('Error removing from Redis set:', err);
            return cb(err, null);
        }
    },

    smembers: async (key, cb) => {
        try {
            const members = await client.sMembers(key);
            return cb(null, members);
        } catch (err) {
            console.error('Error getting members from Redis set:', err);
            return cb(err, null);
        }
    },
};
