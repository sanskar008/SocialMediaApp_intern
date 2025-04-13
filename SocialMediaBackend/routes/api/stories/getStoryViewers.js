const { stories: storiesMongo, storiesInteraction: storiesInteractionMongo, users: usersMongo } = require('../../../db/mongo');
const { FIELDS: USER_FIELDS } = require('../../../db/mongo/users');
const { FIELDS: INTERACTION_FIELDS } = require('../../../db/mongo/storiesInteraction');

const getStoryViewers = {};

getStoryViewers.validateRequest = (req, res, next) => {
  const { storyId } = req.query;
  const userId = req.userId;

  if (!storyId || !userId) {
    return res.status(400).json({
      message: 'Missing required fields: storyId or userId',
    });
  }

  next();
};

getStoryViewers.checkStoryOwnership = async (req, res, next) => {
    const { storyId } = req.query;
    const userId = req.userId;

  try {
    const isOwner = await storiesMongo.instance.doesStoryBelongToUser(storyId, userId);

    if (!isOwner) {
      return res.status(403).json({
        message: 'You do not have permission to view this story.',
      });
    }

    next();
  } catch (err) {
    console.error('Error checking story ownership:', err.message);
    return res.status(500).json({
      message: 'Failed to verify story ownership.',
    });
  }
};

getStoryViewers.fetchViewers = async (req, res, next) => {
  const { storyId } = req.query;

  try {
    const interactions = await storiesInteractionMongo.instance.getInteractionsByStory(storyId);

    if (!interactions.length) {
        return res.status(200).json({
            message: 'No Viewers are there.',
            viewers: {},
            });
    }

    req.body.viewerIds = interactions.map(interaction => interaction[INTERACTION_FIELDS.USER_ID]);
    next();
  } catch (err) {
    console.error('Error fetching viewers:', err.message);
    return res.status(500).json({
      message: 'Failed to fetch viewers for this story.',
    });
  }
};

getStoryViewers.fetchUserDetails = async (req, res, next) => {
  const { viewerIds } = req.body;

  try {
    const userDetails = await usersMongo.instance.getUserDetailsFromIds(viewerIds);

    req.body.viewerDetails = viewerIds.map(userId => {
      const user = userDetails.find(user => user && user._id.toString() === userId.toString());
      return user ? {
        userId: user._id.toString(),
        name: user[USER_FIELDS.NAME],
        profilePic: user[USER_FIELDS.PROFILE_PIC],
      } : null;
    }).filter(user => user);

    next();
  } catch (err) {
    console.error('Error fetching user details:', err.message);
    return res.status(500).json({
      message: 'Failed to fetch user details for viewers.',
    });
  }
};

getStoryViewers.buildResponse = (req, res) => {
  const { viewerDetails } = req.body;

  res.status(200).json({
    message: 'Viewers fetched successfully.',
    viewers: viewerDetails,
  });
};

module.exports = getStoryViewers;
