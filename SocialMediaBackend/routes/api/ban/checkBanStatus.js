const { bannedUsers: bannedUsersMongo } = require('../../../db/mongo');

const checkBanStatus = {};

checkBanStatus.validateRequest = (req, res, next) => {
  const { userId } = req.query;
  
  if (!userId) {
    return res.status(400).json({ 
      message: 'Missing required parameter: userId' 
    });
  }
  
  req.banStatusData = { userId };
  next();
};

checkBanStatus.checkStatus = async (req, res, next) => {
  try {
    const { userId } = req.banStatusData;
    
    const result = await bannedUsersMongo.instance.isUserBanned(userId);
    
    req.banStatus = result;
    next();
  } catch (err) {
    console.error('Error in checkStatus:', err.message);
    res.status(500).json({ message: 'Failed to check ban status' });
  }
};

checkBanStatus.buildResponse = (req, res) => {
  res.status(200).json({ 
    message: 'Ban status checked successfully',
    data: req.banStatus
  });
};

module.exports = checkBanStatus;