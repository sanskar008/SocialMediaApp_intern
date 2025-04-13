const { blockedUsers: blockedUsersMongo } = require('../../../db/mongo');
const { instance: usersMongo } = require('../../../db/mongo/users');

const getBlockedUsers = {};

/**
 * Validate the request (ensuring the user is authenticated).
 */
getBlockedUsers.validateRequest = (req, res, next) => {
  if (!req.userId) {
    return res.status(400).json({ message: 'Missing user id' });
  }
  next();
};

/**
 * Fetch the list of users that the current user has blocked.
 */
getBlockedUsers.fetchBlockedUsers = async (req, res, next) => {
  try {
    const blocker = req.userId;
    const records = await blockedUsersMongo.instance.getBlockedUsers(blocker);
    req._blockedUsers = records;
    next();
  } catch (err) {
    console.error('Error fetching blocked users:', err.message);
    res.status(500).json({ message: 'Failed to fetch blocked users' });
  }
};

/**
 * Middleware to fetch showing details for each blocked user.
 * It extracts the blocked user IDs from the blocked records and retrieves
 * their displayable details (such as profilePic and name) using the Users module.
 */
getBlockedUsers.getUsersShowingDetails = async (req, res, next) => {
  try {
    // Extract the list of blocked user IDs from the records
    const blockedUserIds = req._blockedUsers.map(record => record.blocked);
    // Retrieve user showing details for these IDs
    const userDetails = await usersMongo.getUserShowingDetails(blockedUserIds);
    req._blockedUserDetails = userDetails;
    next();
  } catch (err) {
    console.error('Error fetching blocked user details:', err.message);
    res.status(500).json({ message: 'Failed to fetch blocked user details' });
  }
};

/**
 * Build the API response with the fetched blocked users and their details.
 */
getBlockedUsers.buildResponse = (req, res) => {
  res.status(200).json({
    message: 'Blocked users fetched successfully',
    // blockedUsers: req._blockedUsers,
    blockedUsers: req._blockedUserDetails,
  });
};

module.exports = getBlockedUsers;
