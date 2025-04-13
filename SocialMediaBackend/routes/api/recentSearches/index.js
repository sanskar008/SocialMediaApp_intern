const express = require('express');
const router = express.Router();

const auth = require('../auth')
const addRecentSearch = require('./addRecentSearch');
const removeRecentSearch = require('./removeRecentSearch');
const clearRecentSearches = require('./clearRecentSearches');
const getRecentSearches = require('./getRecentSearches');

router.post('/add-recent-search',
  auth.validateUser,
  addRecentSearch.validateRequest,
  addRecentSearch.addSearch,
  addRecentSearch.buildResponse
);

router.post('/remove-recent-search',
  auth.validateUser,
  removeRecentSearch.validateRequest,
  removeRecentSearch.removeSearch,
  removeRecentSearch.buildResponse
);

router.delete('/clear-recent-searches',
  auth.validateUser,
  clearRecentSearches.clearAll,
  clearRecentSearches.buildResponse
);

router.get('/get-recent-searches',
  auth.validateUser,
  getRecentSearches.validateRequest,
  getRecentSearches.fetchSearches,
  getRecentSearches.buildResponse
);

module.exports = router;