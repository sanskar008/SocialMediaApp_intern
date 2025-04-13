const {messageInteractions : messageInteractionsMongo } = require('./../../../db/mongo')
const reactions = {
    DELIVERED : 'delivered',
    SEEN: 'seen',
    DELETED : 'deleted'
}
const messageInteraction = {}

messageInteraction.validateBody = async(req,res,next) => {
    const { entityId, reactionType} = req.body;

    if(!entityId || !reactionType) return res.status(400).json({success:false, message: 'Missing Json Body'})
    if(!Object.values(reactions).includes(reactionType)) return res.status(400).json({success:false, message: 'Invalid Reaction type on Message'})
    return next();
    
}

messageInteraction.saveToMongo = async(req,res,next) => {
    const { entityId, reactionType} = req.body;
    const userId = req.userId;

    try{
        const addReaction = await messageInteractionsMongo.instance.createInteraction(entityId, userId, reactionType)

        return res.status(200).json({success:true , message  : 'Reaction added for message Successfully'})
    }
    catch{

    }

}

module.exports = messageInteraction