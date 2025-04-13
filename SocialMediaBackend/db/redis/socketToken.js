const query = require("./query");
const keys = require("./keys");
const moment = require('moment');

const socketToken = {};

socketToken.save = (userId, socketToken) => {
  return new Promise((resolve, reject) => {
    const key = keys.SOCKET_TOKEN(userId);
    query.hmset(key, {
      TOKEN: socketToken,
      USER_ID: userId.toString(),
      CREATED_AT: moment().valueOf()
    }, (err) => {
      if(err) return reject(err);
      resolve();
    });
  });
};

socketToken.get = (userId) => {
    return new Promise((resolve, reject) => {
      const key = keys.SOCKET_TOKEN(userId);
      query.hget({ key, field: 'TOKEN' }, (err, result) => {
        if (err) return reject(err);
        resolve(result ? result : null);
      });
    });
  };

module.exports = socketToken;
