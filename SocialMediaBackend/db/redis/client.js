const redis = require('redis');

// Initialize the Redis client
const client = redis.createClient();

client.on('error', (err) => {
    console.error('Redis error:', err);
})
.on('error',       err => console.log('Redis Client Error', err))                                
.on('connect'     , () => console.log('REDIS connected NOW'))
.on('ready'       , () => console.log('REDIS ready to use now'))
.connect();

module.exports = client;
