const { instance: ElasticSearchDBInstance } = require('./db');
const users = require('./users');

const elastic = {};

elastic.initialize = async () => {
  await ElasticSearchDBInstance.connect();
  await users.instance.init();
};

elastic.users = users;

module.exports = elastic;
