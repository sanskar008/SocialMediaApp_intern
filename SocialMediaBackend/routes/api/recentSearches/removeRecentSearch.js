const { recentSearches: recentSearchesMongo } = require('../../../db/mongo');

const removeRecentSearch = {};

removeRecentSearch.validateRequest = (req, res, next) => {
    const { searchedUserId } = req.body;
    
    if (!searchedUserId) {
        return res.status(400).json({ 
            success: false,
            message: 'searchedUserId is required in request body' 
        });
    }

    req.searchData = { searchedUserId };
    next();
};

removeRecentSearch.removeSearch = async (req, res, next) => {
    const { userId } = req;
    const { searchedUserId } = req.searchData;

    try {
        const result = await recentSearchesMongo.instance.removeRecentSearch(
            userId, 
            searchedUserId
        );
        
        req.searchResult = result;
        next();
    } catch (err) {
        console.error('Error in removeRecentSearch:', err.message);
        next({ 
            status: 500, 
            message: 'Failed to remove from recent searches',
            success: false
        });
    }
};

removeRecentSearch.buildResponse = (req, res) => {
    res.status(200).json({ 
        success: true,
        message: 'Search removed from recent searches successfully',
        data: req.searchResult
    });
};

module.exports = removeRecentSearch;