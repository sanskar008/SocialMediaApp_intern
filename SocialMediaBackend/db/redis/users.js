const query = require('./query'); // Existing set and get utility functions
const keys = require('./keys')


const user = {}

user.addUser = async (userId, updatedJson) => {
        return new Promise((resolve, reject) => {
            const key = keys.USERS_DATA(userId)
            query.set(key, JSON.stringify(updatedJson) , (err,result) => {
                if(err) reject(err)
                resolve(result);
            })
          })
};

user.getUserDetails = async (userId) => {
    return new Promise((resolve, reject) => {
        const key = keys.USERS_DATA(userId)
        query.get(key, (error, result) => {
          if(error) reject(error)
          else resolve(result);
        })
      })
};

user.setUserDetails = async (userId, userJson) => {
  return new Promise((resolve, reject) => {
      const key = keys.USERS_DATA(userId); // Redis key for user data
      query.set(key, JSON.stringify(userJson), (err, result) => {
          if (err) reject(err);
          resolve(result); // Return the result (success/failure)
      });
  });
};

module.exports = user
