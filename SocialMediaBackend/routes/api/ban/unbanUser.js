const { bannedUsers: bannedUsersMongo } = require('../../../db/mongo');

const unbanUser = {};

unbanUser.validateRequestBody = (req, res, next) => {
  const { userId } = req.body;
  
  if (!userId) {
    return res.status(400).json({ 
      message: 'Missing required field: userId' 
    });
  }
  
  req.unbanData = { userId };
  next();
};

unbanUser.unbanUser = async (req, res, next) => {
  try {
    const { userId } = req.unbanData;
    
    const result = await bannedUsersMongo.instance.unbanUser(userId);
    
    req.unbanResult = {
      success: result.success,
      count: result.count
    };
    next();
  } catch (err) {
    console.error('Error in unbanUser:', err.message);
    res.status(500).json({ message: 'Failed to unban user' });
  }
};

unbanUser.buildResponse = (req, res) => {
  res.status(200).json({ 
    message: 'User unbanned successfully',
    data: req.unbanResult
  });
};

module.exports = unbanUser;