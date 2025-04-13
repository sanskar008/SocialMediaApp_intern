const { FIELDS: REACTION_FIELDS } = require('../../../db/mongo/reactions');
const { comments:commentsMongo , reactions: reactionsMongo, feeds : FeedsMongo , stories : storiesMongo} = require('../../../db/mongo');
const reaction = require('../../notifications/reaction');

const addReaction = {};
const allowedEntityTypes = {
    FEED: 'feed',
    COMMENT: 'comment',
    STORY: 'story'
};

addReaction.validateBody = (req, res, next) => {
    const { entityId, reactionType, entityType } = req.body;

    if (!entityId || !reactionType || !entityType) {
        return res.status(400).json({ message: 'Missing JSON Body' });
    }

    if (!Object.values(allowedEntityTypes).includes(entityType)) {
        return res.status(400).json({ message: 'Invalid entityType' });
    }

    next();
};

addReaction.checkEntityType = async(req,res,next)=> {
    const { entityType, entityId } = req.body;

    let feedsInstance = null

    if(entityType == allowedEntityTypes.FEED){
        feedsInstance = await FeedsMongo.forId(entityId);
        const result = await feedsInstance.getPostById(entityId);
        req.post = result;
        if(!result) return res.status(404).json({success:'false',message: 'Feed not Found'})
    }
    else if(entityType == allowedEntityTypes.STORY){
        const result = await storiesMongo.instance.getStoryById(entityId);
        req.story = result;
        if(!result) return res.status(404).json({success:'false',message: 'Feed not Found'})
    }

    return next()
}

addReaction.postReaction = async (req, res, next) => {
    try {
        const { entityId, reactionType, entityType } = req.body;
        const userId = req.userId;

        const newReaction = {
            [REACTION_FIELDS.USER_ID]: userId,
            [REACTION_FIELDS.ENTITY_ID]: entityId,
            [REACTION_FIELDS.REACTION_TYPE]: reactionType,
            [REACTION_FIELDS.ENTITY_TYPE]: entityType,
            [REACTION_FIELDS.CREATED_AT]: new Date()
        };

        let receiverId = null;

        if (entityType === allowedEntityTypes.FEED) {
            receiverId = req.post?.author;
        }
        else if (entityType === allowedEntityTypes.COMMENT) {
            const comment = await commentsMongo.instance.findComment(entityId);
            receiverId = comment?.user_id;
        }
        else if (entityType === allowedEntityTypes.STORY) {
            receiverId = req.story?.author;
        }

        const reactionId = await reactionsMongo.instance.addReaction(newReaction);

        // Send Like Notification
        reaction.send({ senderId : req.userId, receiverId, entityId, entityType , reactionId , post :req.post });

        next();
    } catch (error) {
        res.status(500).json({ message: 'Internal Server Error', error: error.message });
    }
};

addReaction.buildResponse = (req, res, next) => {
    return res.status(200).json({ message: 'Reaction added successfully' });
};

module.exports = addReaction;