
const query = require("./query");
const keys = require("./keys");
const moment = require('moment');

const sso = {};

const fields = {
  USER_ID: 'USER_ID',
  CREATED_AT: 'CREATED_AT',
  TOKEN: 'TOKEN'
}

sso.fields = fields;

sso.save = (userId, token) => {
  return new Promise((resolve, reject) => {
    const key = keys.SSO_TOKEN(userId);
    console.log(key,token,'TOKEN')
    query.hmset(key, {
      [fields.TOKEN]: token,
      [fields.USER_ID]: userId.toString(),
      [fields.CREATED_AT]: moment().valueOf() 
    }, () => {
      resolve();
    })
  })
}

sso.remove = (userId) => {
  return new Promise((resolve, reject) => {
    const key = keys.SSO_TOKEN(userId)
    query.del(key ,(err, deleted)=>{
      if(err) {
          reject(err)
      } else {
          resolve(deleted)
      }
    })  
  })
}


sso.get = (userId) => {
  return new Promise((resolve, reject) => {
    const key = keys.SSO_TOKEN(userId);
    query.hget({
      key, field: fields.TOKEN
    }, (error, result) => {
      resolve(result ? result : null);
    })
  })
}


module.exports = sso;