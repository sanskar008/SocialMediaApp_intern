const express = require('express');
const router = express.Router();

const createPost= require('./createPost')
const auth = require('../auth');
const getAllPosts = require('./getAllPosts');
const editPost = require('./editPost');
const deletePost = require('./deletePost');
const mediaUpload = require('../../../media/upload');
const getHomePagePosts = require('./getHomePagePosts');
const blockService = require('../blockService');
const getPostDetails = require('./getPostDetails');

router.post('/post',
    auth.validateUser,
    createPost.formDataWrapper,
    createPost.validateBody,
    mediaUpload.uploader,
    createPost.saveToMongo,
    createPost.saveInEs,
    createPost.buildResponse,
    createPost.sendMentionedNotifications,
    createPost.sendTaggedNotification
)
//for self , if passed userId in params , then for someone else
router.get('/get-posts',
    auth.validateUser,
    getAllPosts.validateRequest,
    getAllPosts.checkUserPostVisibility,
    getAllPosts.fetchPostsFromMongo,
    getAllPosts.addPostActions,
    getAllPosts.addUserDetails,
    getAllPosts.buildResponse
);
//home page pe jo follwings ki post dikhegi , currently without algo
router.get('/get-home-posts',
    auth.validateUser, 
    getHomePagePosts.getAllFollowings,
    blockService.filterBlockIdsMiddleware,
    getHomePagePosts.fetchPostsFromFollowings,
    getHomePagePosts.fetchPostsFromCommunities,
    getHomePagePosts.combineAndProcessPosts,
    getHomePagePosts.addUserDetails,
    getHomePagePosts.buildResponse
);

router.put('/edit-post', 
    auth.validateUser, 
    editPost.validateRequestBody, 
    editPost.verifyPostBelongsToUser,
    editPost.updatePost,
    editPost.buildResponse 
);

router.delete('/delete-post', 
    auth.validateUser, 
    deletePost.validateRequest, 
    deletePost.deleteFromMongo, 
    deletePost.buildResponse 
);

router.post('/rewriteWithBond',
   // auth.validateUser,
    createPost.rewriteWithBond
);

router.get('/get-post-details',
    auth.validateUser,
    getPostDetails.validateRequest,
    getPostDetails.fetchPost,
    getPostDetails.addAuthorDetails,
    getPostDetails.checkPostVisibility,
    getPostDetails.addCommentAndReactionCounts,
    getPostDetails.buildResponse
);
  

module.exports = router