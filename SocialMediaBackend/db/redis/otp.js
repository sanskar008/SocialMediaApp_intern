const client = require('./client'); // Import the Redis client
const query = require('./query'); // Existing set and get utility functions
const keys = require('./keys')


const OTP_EXPIRATION_TIME = (1)*60; // 1 minute
const REQUEST_COUNT_EXPIRATION = (15)*60; // 15 minutes



const userOtp = {

    getOtpInfo: async(phoneNumber , countryCode) => {
        return new Promise((resolve, reject) => {
            const key = keys.OTP_DATA(countryCode,phoneNumber)
            query.get(key, (error, result) => {
              if(error) reject(error)
              else resolve(result);
            })
          })
    },

    setOtp: async (phoneNumber, countryCode , otp) => {
        return new Promise((resolve, reject) => {
            const key = keys.OTP_DATA(countryCode,phoneNumber)
            query.set(key, otp , (err,result) => {
                if(err) reject(err)
                query.expire(key, OTP_EXPIRATION_TIME)
                resolve(result);
            })
          })
        
    },

    setRequestCount: async (phoneNumber, countryCode , currentCount) => {
        const countKey = keys.REQUEST_COUNT(phoneNumber,countryCode)
        if (!currentCount) {
            await query.setWithExpiry(countKey, 1, REQUEST_COUNT_EXPIRATION);
        } else {    
            const ttl = await query.getTTL(countKey);
            if (ttl > 0) {

                await query.setWithExpiry(countKey, currentCount + 1, ttl);
            } else {
                await query.setWithExpiry(countKey, currentCount + 1, REQUEST_COUNT_EXPIRATION);
            }
        }
    },
    getRequestCount: async (phoneNumber, countryCode) => {
        const countKey = keys.REQUEST_COUNT(phoneNumber, countryCode);
    
        return new Promise((resolve, reject) => {
            query.get(countKey, (error, result) => {
                if (error) {
                    return reject(error); 
                }
    
                const currentCount = parseInt(result, 10) || 0; 
                resolve(currentCount); 
            });
        });
    }
    
    
};

module.exports = userOtp
