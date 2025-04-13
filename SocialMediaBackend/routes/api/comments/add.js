const { comments: commentsMongo, feeds : FeedsMongo } = require('../../../db/mongo');
const { FIELDS: COMMENT_FIELDS } = require('../../../db/mongo/comments');
const commentNotification = require("../../notifications/comment");
const moment = require('moment')
const addComment ={}

addComment.validateBody = (req,res,next)=> {
    const { comment, postId } = req.body;

    if(!comment || !postId) return res.status(400).json({success:false,message:'Missing JSON Body'})
    return next();
}

addComment.checkExistence = async(req,res,next)=> {
    const { postId , parentComment } = req.body;

     let feedsInstance = null
    
    
        feedsInstance = await FeedsMongo.forId(postId);
        const result = await feedsInstance.getPostById(postId);
        if(!result) return res.status(404).json({success:'false',message: 'Feed not Found'})

        req._post = result;

    if(parentComment) {
        const parent = await commentsMongo.instance.findComment(parentComment);
        if(!parent) return res.status(404).json({success:false, message:'No comment Found to reply'})
    }
    return next()
}

addComment.saveInMongo = async(req,res,next) => {
    const { comment, parentComment , postId } = req.body;

    const toAdd = {
        [COMMENT_FIELDS.COMMENT] : comment,
        [COMMENT_FIELDS.POST_ID] : postId,
        [COMMENT_FIELDS.PARENT_COMMENT] : parentComment,
        [COMMENT_FIELDS.USER_ID] : req.userId,
        [COMMENT_FIELDS.CREATED_AT] : moment.unix()
    }

    const result = await commentsMongo.instance.addComment(toAdd);
    req.result = result;

    commentNotification.send({
        senderId: req.userId,
        post : req._post,
        commentText: comment,
        commentId: result.insertedId.toString(),
    });

    return next();
}

addComment.buildResponse = (req,res,next)=> {
    const result = req.result;
    return res.status(200).json({success:true, message:'Comment Added Successfully' , comment : result})
}

module.exports = addComment