const { bannedUsers: bannedUsersMongo } = require('../../../db/mongo');

const banUser = {};

banUser.validateRequestBody = (req, res, next) => {
  const { userId, banTill, reason } = req.body;
  
  if (!userId || !banTill) {
    return res.status(400).json({ 
      message: 'Missing required fields: userId and banTill are required' 
    });
  }
  
  if (userId === req.userId) {
    return res.status(400).json({ message: 'You cannot ban yourself' });
  }
  
  req.banData = {
    userId,
    banTill: new Date(banTill),
    reason: reason || ''
  };
  
  next();
};

banUser.banUser = async (req, res, next) => {
  try {
    const { userId, banTill, reason } = req.banData;
    // const moderatorId = req.userId; // Assuming you'll add auth later
    
    const result = await bannedUsersMongo.instance.banUser(
      userId, 
      banTill, 
      reason, 
    //   moderatorId
    );
    
    req.banResult = result;
    next();
  } catch (err) {
    console.error('Error in banUser:', err.message);
    res.status(500).json({ message: 'Failed to ban user' });
  }
};

banUser.buildResponse = (req, res) => {
  res.status(200).json({ 
    message: 'User banned successfully',
    data: req.banResult
  });
};

module.exports = banUser;