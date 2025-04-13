const { blockedUsers: blockedUsersMongo } = require('../../../db/mongo');

const unblockUser = {};

/**
 * Validate the request body to ensure a blocked user ID is provided.
 */
unblockUser.validateRequestBody = (req, res, next) => {
  const { blocked } = req.body;
  if (!blocked) {
    return res.status(400).json({ message: 'Missing required field: blocked user id' });
  }
  next();
};

/**
 * Unblock a user by removing the record from the blockedUsers collection.
 */
unblockUser.unblockUser = async (req, res, next) => {
  try {
    const blocker = req.userId;
    const { blocked } = req.body;
    const result = await blockedUsersMongo.instance.unblockUser({ blocker, blocked });
    req._unblockResult = result;
    next();
  } catch (err) {
    console.error('Error in unblockUser:', err.message);
    res.status(500).json({ message: 'Failed to unblock user' });
  }
};

/**
 * Build the API response after successfully unblocking a user.
 */
unblockUser.buildResponse = (req, res) => {
  res.status(200).json({ message: 'User unblocked successfully' });
};

module.exports = unblockUser;