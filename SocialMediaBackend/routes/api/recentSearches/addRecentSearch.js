const { recentSearches: recentSearchesMongo  , users : usersMongo} = require('../../../db/mongo');

const addRecentSearch = {};

addRecentSearch.validateRequest = async (req, res, next) => {
    const { searchedUserId } = req.body;
    
    if (!searchedUserId) {
        return res.status(400).json({ 
            success: false,
            message: 'searchedUserId is required in request body' 
        });
    }

    try {
        // Check if searched user exists in database
        const userExists = await usersMongo.instance.getUserDetailsFromId(searchedUserId);
        
        if (!userExists) {
            return res.status(404).json({
                success: false,
                message: 'Searched user does not exist'
            });
        }

        req.searchData = { 
            searchedUserId
        };
        next();
    } catch (err) {
        console.error('Error validating searched user:', err.message);
        return res.status(500).json({
            success: false,
            message: 'Error validating user existence'
        });
    }
};

addRecentSearch.addSearch = async (req, res, next) => {
    const { userId } = req;
    const { searchedUserId } = req.searchData;

    try {
        const result = await recentSearchesMongo.instance.addRecentSearch(
            userId, 
            searchedUserId
        );
        
        req.searchResult = result;
        next();
    } catch (err) {
        console.error('Error in addRecentSearch:', err.message);
        next({ 
            status: 500, 
            message: 'Failed to add recent search',
            success: false
        });
    }
};

addRecentSearch.buildResponse = (req, res) => {
    res.status(200).json({ 
        success: true,
        message: 'Search added to recent searches successfully',
        data: req.searchResult
    });
};

module.exports = addRecentSearch;