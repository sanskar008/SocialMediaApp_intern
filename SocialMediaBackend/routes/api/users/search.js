const { users: usersElastic } = require('../../../db/elastic');
const { users : usersMongo } = require('../.././../db/mongo')
const search = {};

// Define a maximum limit for results per page
const MAX_RESULTS = 50;

// Validate search query input
search.validateSearchQuery = (req, res, next) => {
  const { searchString, page = 1, size = 10 } = req.body;

  // Check if searchString is provided
  if (!searchString || typeof searchString !== 'string' || searchString.trim().length === 0) {
    return res.status(400).json({
      message: 'Search string must be a non-empty string.',
    });
  }

  // Validate page and size inputs
  if (size > MAX_RESULTS) {
    return res.status(400).json({
      message: `Maximum results per page is ${MAX_RESULTS}.`,
    });
  }

  req.searchParams = { searchString: searchString.trim(), page: parseInt(page, 10), size: parseInt(size, 10) };
  next();
};

// Perform the username search in Elasticsearch
search.searchByUserName = async (req, res, next) => {
  const { searchString, page, size } = req.searchParams;

  try {
    // Perform search using Elasticsearch
    const { total, users } = await usersElastic.instance.searchUserByName(searchString, { page, size });

    if (total === 0) {
      return res.status(200).json({
        message: 'No users found matching the search string.',users
      });
    }

    req._users = users

    req._response = {
      message: 'Search completed successfully.',
      totalResults: total,
      currentPage: page,
      pageSize: size,
    }
    return next();
  } catch (err) {
    console.error('Error performing username search:', err.message);
    next({ status: 500, message: 'Internal Server Error' });
  }
};

search.checkAnonymous = async (req, res, next) => {
  try {
    // Filter out users with privacyLevel equal to 1.
    // Using non-strict comparison ensures that both "1" and 1 match.
    req._users = req._users.filter(user => user.privacyLevel != 1);
    next();
  } catch (err) {
    console.error("Error filtering users:", err.message);
    return res.status(400).json({ message: "Error processing user privacy levels." });
  }
};


search.buildResponse = (req,res,next) => {
  let response = { ...req._response, users: req._users || [] };
  return res.status(200).json(response);
}

module.exports = search;
