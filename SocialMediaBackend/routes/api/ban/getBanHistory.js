const { bannedUsers: bannedUsersMongo } = require('../../../db/mongo');

const getBanHistory = {};

getBanHistory.validateRequest = (req, res, next) => {
  const { userId } = req.query;
  
  if (!userId) {
    return res.status(400).json({ 
      message: 'Missing required parameter: userId' 
    });
  }
  
  req.banHistoryData = { userId };
  next();
};

getBanHistory.fetchBanHistory = async (req, res, next) => {
  try {
    const { userId } = req.banHistoryData;
    const { page = 1, limit = 10 } = req.query;
    
    const result = await bannedUsersMongo.instance.getBanHistory(
      userId,
      parseInt(page),
      parseInt(limit)
    );
    
    req.banHistory = result;
    next();
  } catch (err) {
    console.error('Error in fetchBanHistory:', err.message);
    res.status(500).json({ message: 'Failed to fetch ban history' });
  }
};

getBanHistory.buildResponse = (req, res) => {
  res.status(200).json({ 
    message: 'Ban history fetched successfully',
    data: req.banHistory
  });
};

module.exports = getBanHistory;