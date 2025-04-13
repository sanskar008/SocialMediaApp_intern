const router = require('express').Router();
const auth = require('../auth');
const blockService = require('../blockService');
const addComment = require('./add');
const deleteComment = require('./delete');
const getAllComments = require('./getAllComments');



router.post('/comment',
    auth.validateUser,
    addComment.validateBody,
    addComment.checkExistence,
    addComment.saveInMongo,
    addComment.buildResponse
)

router.delete('/comment',
    auth.validateUser,
    deleteComment.validateBody,
    deleteComment.checkExistence,
    deleteComment.deleteComment,
    deleteComment.buildResponse
)

router.post('/getCommentsForPostId',
    auth.validateUser,
    getAllComments.validateBody,
    getAllComments.fetchComments,
    getAllComments.prepareBlockFilter,
    blockService.filterBlockIdsMiddleware,
    getAllComments.filterOutBlockedComments,
    getAllComments.addUserDetails,
    getAllComments.buildResponse
)
module.exports = router;