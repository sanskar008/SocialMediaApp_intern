const { blockedUsers: blockedUsersMongo } = require('../../db/mongo');

/**
 * Middleware to filter out user IDs that are blocked by or have blocked the current user.
 *
 * Expects:
 *  - req.userId: The current user ID.
 *  - req._toBeFiltered: An array of candidate user IDs to filter.
 *
 * Sets:
 *  - req.fildteredAfterBlockCheckUserIds: The array of user IDs after filtering out blocked relationships.
 */

const blockService = {};

blockService.filterBlockIdsMiddleware = async (req, res, next) => {
  try {
    const userId = req.userId;
    const candidateUserIds = req._toBeFiltered;

    if (!userId || !Array.isArray(candidateUserIds)) {
      next();
    }

    // Fetch the users that the current user has blocked
    const blockedRecords = await blockedUsersMongo.instance.getBlockedUsers(userId);
    // Fetch the users who have blocked the current user
    const blockedByRecords = await blockedUsersMongo.instance.getUsersWhoBlocked(userId);

    // Extract the user IDs from the records
    const blockedUserIds = blockedRecords.map(record => record.blocked.toString());
    const blockedByUserIds = blockedByRecords.map(record => record.blocker.toString());

    // Combine both lists into an exclusion set
    const exclusionSet = new Set([...blockedUserIds, ...blockedByUserIds]);

    // Filter candidate user IDs to exclude any that appear in the exclusion set
    const filteredIds = candidateUserIds.filter(id => !exclusionSet.has(id.toString()));

    // Save the filtered result on the request object for further use in the flow
    req.filteredAfterBlockCheckUserIds = filteredIds;
    next();
  } catch (err) {
    console.error('Error filtering block ids:', err);
    res.status(500).json({ message: 'Internal Server Error while filtering block ids' });
  }
};

module.exports = blockService;