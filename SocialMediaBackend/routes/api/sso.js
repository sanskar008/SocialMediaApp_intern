let randToken = require("rand-token");
const {sso: ssoRedis , socketToken: socketTokenRedis} = require("../../db/redis")

const ssoHelper = {};

ssoHelper.generateAndSave = async(userId) => {
  const token = randToken.generate(64);
  await ssoRedis.save(userId, token);
  return token;
}

ssoHelper.deleteToken = async(userId) => {
  return await ssoRedis.remove(userId)
}

ssoHelper.verify = async(token, userId) => {
  const _token = await ssoRedis.get(userId);
  return (token === _token);
}

ssoHelper.saveSockeToken = async( socketToken , userId ) => {
  await socketTokenRedis.save(userId , socketToken);
}

ssoHelper.verifySocketToken = async( socketToken , userId ) => {
  const _socketToken = await socketTokenRedis.get(userId);
  return ( _socketToken === socketToken );
}

module.exports = ssoHelper;