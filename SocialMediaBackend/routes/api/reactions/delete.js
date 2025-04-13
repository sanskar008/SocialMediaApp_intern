const { FIELDS: REACTION_FIELDS } = require('../../../db/mongo/reactions');
const { reactions: reactionsMongo, feeds: FeedsMongo } = require('../../../db/mongo');

const deleteReaction = {};

const allowedEntityTypes = {
    FEED: 'feed',
    COMMENT: 'comment'
};

deleteReaction.validateBody = (req, res, next) => {
    const { entityId, entityType } = req.body;

    if (!entityId || !entityType) {
        return res.status(400).json({ message: 'Missing JSON Body' });
    }
    return next();
}

deleteReaction.checkEntityType = async (req, res, next) => {
    const { entityType, entityId } = req.body;

    try {
        let feedsInstance = null;

        if (entityType === allowedEntityTypes.FEED) {
            feedsInstance = await FeedsMongo.forId(entityId);
            const result = await feedsInstance.getPostById(entityId);
            if (!result) {
                return res.status(404).json({ success: 'false', message: 'Feed not Found' });
            }
        }
        return next();
    } catch (error) {
        return res.status(500).json({ success: 'false', message: 'Internal Server Error', error: error.message });
    }
}

deleteReaction.fromMongo = async (req, res, next) => {
    const { entityType, entityId } = req.body;

    try {
        const toDel = {
            [REACTION_FIELDS.USER_ID]: req.userId,
            [REACTION_FIELDS.ENTITY_ID]: entityId,
            [REACTION_FIELDS.ENTITY_TYPE]: entityType
        }

        await reactionsMongo.instance.deleteReaction(toDel);
        return next();
    } catch (error) {
        return res.status(500).json({ success: 'false', message: 'Internal Server Error', error: error.message });
    }
}

deleteReaction.buildResponse = (req, res, next) => {
    return res.status(200).json({ success: 'true', message: 'Reaction deleted Successfully' });
}

module.exports = deleteReaction;
