const { blockedUsers: blockedUsersMongo } = require('../../../db/mongo');
const blockUser = {};

/**
 * Validate the request body to ensure a blocked user ID is provided.
 */
blockUser.validateRequestBody = (req, res, next) => {
  const { blocked } = req.body;
  if (!blocked) {
    return res.status(400).json({ message: 'Missing required field: blocked user id' });
  }
  else if ( blocked == req.userId ){
    return res.status(400).json({ message: 'You cant block yourself.' });
  }
  next();
};

/**
 * Block a user by adding/updating a record in the blockedUsers collection.
 */
blockUser.blockUser = async (req, res, next) => {
  try {
    const blocker = req.userId;
    const { blocked } = req.body;
    const result = await blockedUsersMongo.instance.blockUser({ blocker, blocked });
    req._blockResult = result;
    next();
  } catch (err) {
    console.error('Error in blockUser:', err.message);
    res.status(500).json({ message: 'Failed to block user' });
  }
};

/**
 * Build the API response after successfully blocking a user.
 */
blockUser.buildResponse = (req, res) => {
  res.status(200).json({ message: 'User blocked successfully' });
};

module.exports = blockUser;