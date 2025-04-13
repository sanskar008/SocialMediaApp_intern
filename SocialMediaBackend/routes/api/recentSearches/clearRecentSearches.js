const { recentSearches: recentSearchesMongo } = require('../../../db/mongo');

const clearRecentSearches = {};

clearRecentSearches.clearAll = async (req, res, next) => {
    const { userId } = req;

    try {
        const result = await recentSearchesMongo.instance.clearRecentSearches(userId);
        
        req.clearResult = result;
        next();
    } catch (err) {
        console.error('Error in clearRecentSearches:', err.message);
        next({ 
            status: 500, 
            message: 'Failed to clear recent searches',
            success: false
        });
    }
};

clearRecentSearches.buildResponse = (req, res) => {
    res.status(200).json({ 
        success: true,
        message: 'Recent searches cleared successfully',
        data: req.clearResult
    });
};

module.exports = clearRecentSearches;