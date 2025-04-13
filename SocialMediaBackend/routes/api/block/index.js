const express = require('express');
const router = express.Router();
const auth = require('../auth');

const blockUser = require('./blockUser');
const unblockUser = require('./unblockUser');
const getBlockedUsers = require('./getBlockedUser');

// Block a user
router.post('/block-user',
  auth.validateUser,
  blockUser.validateRequestBody,
  blockUser.blockUser,
  blockUser.buildResponse
);

// Unblock a user
router.post('/unblock-user',
  auth.validateUser,
  unblockUser.validateRequestBody,
  unblockUser.unblockUser,
  unblockUser.buildResponse
);

// Get list of users you have blocked
router.get('/get-blocked-users',
  auth.validateUser,
  getBlockedUsers.validateRequest,
  getBlockedUsers.fetchBlockedUsers,
  getBlockedUsers.getUsersShowingDetails,
  getBlockedUsers.buildResponse
);

module.exports = router;