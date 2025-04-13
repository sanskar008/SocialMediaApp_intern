const { 
    recentSearches: recentSearchesMongo,
    users: usersMongo 
} = require('../../../db/mongo');

const getRecentSearches = {};

getRecentSearches.validateRequest = (req, res, next) => {
    // Add any validation logic here if needed
    next();
};

getRecentSearches.fetchSearches = async (req, res, next) => {
    const { userId } = req;

    try {
        const recentSearches = await recentSearchesMongo.instance.getRecentSearches(userId);
        const userIds = recentSearches.map(id => id.toString()); 
        
        const userDetails = await usersMongo.instance.getUserShowingDetails(userIds);
        
        req.searchData = {
            recentSearches: userDetails.filter(Boolean)
        };
        next();
    } catch (err) {
        console.error('Error in getRecentSearches:', err.message);
        next({ 
            status: 500, 
            message: 'Failed to fetch recent searches',
            success: false
        });
    }
};

getRecentSearches.buildResponse = (req, res) => {
    res.status(200).json({ 
        success: true,
        message: 'Recent searches fetched successfully',
        data: req.searchData.recentSearches
    });
};

module.exports = getRecentSearches;