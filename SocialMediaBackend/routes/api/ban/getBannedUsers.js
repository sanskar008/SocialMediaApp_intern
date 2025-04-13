const { bannedUsers: bannedUsersMongo } = require('../../../db/mongo');

const getBannedUsers = {};

getBannedUsers.validateRequest = (req, res, next) => {
  // Add any validation if needed
  next();
};

getBannedUsers.fetchBannedUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    
    const result = await bannedUsersMongo.instance.getActiveBans(
      parseInt(page),
      parseInt(limit)
    );
    
    req.bannedUsers = result;
    next();
  } catch (err) {
    console.error('Error in fetchBannedUsers:', err.message);
    res.status(500).json({ message: 'Failed to fetch banned users' });
  }
};

getBannedUsers.buildResponse = (req, res) => {
  res.status(200).json({ 
    message: 'Banned users fetched successfully',
    data: req.bannedUsers
  });
};

module.exports = getBannedUsers;