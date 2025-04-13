const { stories : storiesMongo ,followers : followersMongo , storiesInteraction : storiesInteractionMongo } = require('../../../db/mongo')

const saveInteraction = {};

saveInteraction.validateRequestBody = (req, res, next) => {
  const { storyId } = req.body;

  if (!storyId) {
    return res.status(400).json({ message: 'Story ID is required' });
  }

  next();
};

saveInteraction.checkStoryExists = async (req, res, next) => {
  const { storyId } = req.body;

  try {
    const storyExists = await storiesMongo.instance.getStoryMetadata(storyId);

    if (!storyExists) {
      return res.status(404).json({ message: 'Story not found' });
    }

    next();
  } catch (err) {
    console.error('Error checking if story exists:', err.message);
    return res.status(500).json({ message: 'Failed to validate story existence' });
  }
};

saveInteraction.saveToDB = async (req, res, next) => {
  const { storyId } = req.body;
  const userId = req.userId;

  try {
    const interaction = await storiesInteractionMongo.instance.saveInteraction({
      storyId,
      userId,
    });

    if (!interaction) {
      return res.status(500).json({ message: 'Failed to save interaction' });
    }

    next();
  } catch (err) {
    console.error('Error saving interaction:', err.message);
    return res.status(500).json({ message: 'Failed to save interaction' });
  }
};

saveInteraction.buildResponse = (req, res) => {
  res.status(200).json({
    message: 'Interaction saved successfully',
  });
};


module.exports = saveInteraction;
