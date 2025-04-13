const express = require('express');
const router = express.Router();

const auth = require('../adminAuth');
const banUser = require('./banUser');
const unbanUser = require('./unbanUser');
const getBanHistory = require('./getBanHistory');
const getBannedUsers = require('./getBannedUsers');
const checkBanStatus = require('./checkBanStatus');

router.post('/ban-user',
  auth.validateUser,
  banUser.validateRequestBody,
  banUser.banUser,
  banUser.buildResponse
);

router.post('/unban-user',
  auth.validateUser,
  unbanUser.validateRequestBody,
  unbanUser.unbanUser,
  unbanUser.buildResponse
);

router.get('/get-banned-users',
  auth.validateUser,
  getBannedUsers.validateRequest,
  getBannedUsers.fetchBannedUsers,
  getBannedUsers.buildResponse
);

router.get('/ban-history',
  auth.validateUser,
  getBanHistory.validateRequest,
  getBanHistory.fetchBanHistory,
  getBanHistory.buildResponse
);

router.get('/check-ban-status',
  auth.validateUser,
  checkBanStatus.validateRequest,
  checkBanStatus.checkStatus,
  checkBanStatus.buildResponse
);

module.exports = router;