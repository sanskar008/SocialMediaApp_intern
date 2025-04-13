const { stories: storiesMongo } = require('../../../db/mongo'); 
const { FIELDS, FIELDS_VALUES } = require('../../../db/mongo/stories'); 

const archieveStory = {};

archieveStory.validateRequestBody = (req, res, next) => {
    const { storyId } = req.body;

    if (!storyId) {
        return res.status(400).json({ message: 'Story ID is required.' });
    }

    next();
};

archieveStory.checkStoryExistsAndNotArchived = async (req, res, next) => {
    const { storyId } = req.body;

    try {
        const story = await storiesMongo.instance.getStoryMetadata(storyId); 

        if (!story) {
            return res.status(404).json({ message: 'Story not found.' });
        }

        if (story.status === FIELDS_VALUES[FIELDS.STATUS].ARCHIEVED) {
            return res.status(400).json({ message: 'Story is already archived.' });
        }

        req.story = story; 
        next();
    } catch (err) {
        console.error('Error checking story status:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

archieveStory.checkStoryOwnership = (req, res, next) => {
    const { story } = req;
    const userId = req.userId; // Assuming userId is already set in the request object

    if (story.author.toString() !== userId.toString()) {
        return res.status(403).json({ message: 'You are not authorized to archive this story.' });
    }

    next();
};

archieveStory.archiveStory = async (req, res, next) => {
    const { storyId } = req.body;

    try {
        const result = await storiesMongo.instance.archieveStory(storyId);

        if (result.matchedCount === 0) {
            return res.status(400).json({ message: 'Failed to archive story' });
        }

        req.archivedStory = result;
        next(); 
    } catch (err) {
        console.error('Error archiving story:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

archieveStory.buildResponse = (req, res) => {
    res.status(200).json({
        message: 'Story archived successfully.',
        storyId: req.body.storyId,
        archived: true,
    });
};

module.exports = archieveStory;
