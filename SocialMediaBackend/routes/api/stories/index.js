const express = require('express');
const router = express.Router();
const auth = require('../auth');

const uploadStory = require('./uploadStory'); 
const getStories = require('./getStories');
const mediaUpload = require('../../../media/upload');
const archieveStory = require('./archieveStory');
const saveInteraction = require('./saveInteraction');
const getStoryViewers = require('./getStoryViewers');
const blockService = require('../blockService');

router.post('/upload-story',
    auth.validateUser, 
    uploadStory.formDataWrapper,
    uploadStory.validateRequestBody,
    mediaUpload.uploader,
    uploadStory.saveStoryToDB,
    uploadStory.buildResponse
);

//mere sare followers ki stories
router.get('/get-stories',
    auth.validateUser,  
    getStories.getAllFollowings,
    getStories.addLiveStreams,
    getStories.setUserIdsOrder,
    getStories.getStoriesFromFollowings,
    getStories.setUserData,
    getStories.setSeen,
    getStories.prepareStoriesBlockFilter,
    blockService.filterBlockIdsMiddleware,
    getStories.applyStoriesBlockFilter,
    getStories.buildResponse  
);
//particular user profile pe dikhne wali story
router.post('/get-story-for-user',
    auth.validateUser,
    getStories.validateRequest,
    getStories.followingCheck,
    getStories.setUserIdsOrder,
    getStories.getStoriesFromFollowings,
    getStories.setUserData,
    getStories.setSeen,
    getStories.buildResponse  
)
//khudki stories
router.get('/get-self-stories',
    auth.validateUser,
    getStories.getSelfStories,
    getStories.setHasViewed
)

router.post('/archieve-story',
    auth.validateUser,
    archieveStory.validateRequestBody,
    archieveStory.checkStoryExistsAndNotArchived, 
    archieveStory.checkStoryOwnership,
    archieveStory.archiveStory,  
    archieveStory.buildResponse  
);

router.post('/save-interaction',
    auth.validateUser,
    saveInteraction.validateRequestBody,
    saveInteraction.checkStoryExists,
    saveInteraction.saveToDB,
    saveInteraction.buildResponse
);

router.get('/get-story-viewers',
    auth.validateUser,
    getStoryViewers.validateRequest,
    getStoryViewers.checkStoryOwnership,
    getStoryViewers.fetchViewers,
    getStoryViewers.fetchUserDetails,
    getStoryViewers.buildResponse
)

module.exports = router;
