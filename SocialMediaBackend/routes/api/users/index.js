const express = require('express');
const router = express.Router();
const editProfile = require('./editProfile');
const auth = require('../auth');
const adminAuth = require('../adminAuth');
const login = require('./login');
const password = require('./password');
const mediaUpload = require('../../../media/upload');
const follower = require('./follow');
const relationship = require('./relationship');
const showProfile = require('./showProfile');
const { users } = require('../../../db/elastic/');
const botUser = require('./bot');
const search = require('./search');
const file = require('./file');
const avatar = require('./avatar');
const getUsers = require('./getUsers');

// Route to edit user profile
router.put('/edit-profile', 
    auth.validateUser,
    editProfile.validateRequestBody, // Validate the fields provided in the body
    mediaUpload.uploader, 
    editProfile.updateProfile, // Update the profile in the database
    editProfile.manageToken,
    editProfile.buildResponse
);
router.put('/set-password',
    auth.validateUser,
    password.validateSetPasswordRequestBody,
    password.setNewPassword
)
router.get('/chalebi',async(req , res) => {
    const h =  await users.instance.getAllUsers();
    return res.status(201).json(h);
}
)
router.post('/search',
    auth.validateUser,
    search.validateSearchQuery, // Validate the search input
    search.searchByUserName,
    search.checkAnonymous,
    relationship.buildRelation,
    search.buildResponse
)

router.post('/reset-password',
    password.validateResetPasswordRequestBody,
    password.verifyOldPassword,
    password.setNewPassword
)

router.post('/forgot-password',
    password.validateSetPasswordRequestBody,
    password.setNewPassword
)

router.post('/pre-login-check',
    login.preLoginValidateRequestBody,
    login.preLoginSendStatusCode
)

router.post('/login',
    login.validateRequestBody,
    login.getUserDetailsFromDB,
    login.verifyPassword,
    login.generateAndSaveTokens,
    login.buildResponse
)

router.post('/sendRequest',
    auth.validateUser,
    follower.validateSendOrCancelRequestBody,
    follower.checkAlreadyExistingRequest,
    follower.sendRequest
);

router.put('/acceptRequest',
    auth.validateUser,
    follower.validateAcceptRejectRemoveBody,
    follower.acceptRequest
);

router.put('/rejectRequest',
    auth.validateUser,
    follower.validateAcceptRejectRemoveBody,
    follower.rejectRequest
);

router.post('/cancelRequest',
    auth.validateUser,
    follower.validateSendOrCancelRequestBody,
    follower.cancelRequest
);

router.get('/followersCount', 
    auth.validateUser,
    follower.getFollowCounts
);

router.get('/followRequests',
    auth.validateUser,
    follower.getPendingRequests,
    showProfile.showUserDetails

)

router.get('/followers',
    auth.validateUser,
    follower.getFollowers,
    showProfile.showUserDetails

)

router.get('/followings',
    auth.validateUser,
    follower.getFollowings,
    showProfile.showUserDetails

)

router.post('/follower/remove',
    auth.validateUser,
    follower.validateAcceptRejectRemoveBody,
    follower.checkFollowerAndRemove
)

router.post('/unfollow',
    auth.validateUser,
    follower.validateAcceptRejectRemoveBody,
    follower.areRelated,
    follower.unfollow
)



router.get('/showProfile',
    auth.validateUser,
    showProfile.validateBody,
    showProfile.fetchUserDetails,
    relationship.buildRelation,
    relationship.sendResponse
)


router.post('/fileUpload',
    auth.validateUser,
    file.entityType,
    mediaUpload.uploader,
    file.response
)

router.post('/create/bot',
    adminAuth.validateUser,
    botUser.check,
    botUser.validateBody,
    botUser.createBot
)

router.get('/botDetails',
    adminAuth.validateUser,
    botUser.getDetails
)

router.get('/get-avatars',
    auth.validateUser,
    avatar.sendLinks
)

router.get('/getAllUsers',
    auth.validateUser,
    showProfile.getAllUsers
)

router.get('/getRandomText',
    auth.validateUser,
    showProfile.getRandomText
)

router.post('/community/action',
    auth.validateUser,
    editProfile.joinCommunity
)

router.get('/getUsers',
    adminAuth.validateUser,
    getUsers.validateRequest,
    getUsers.getThem,
    getUsers.buildResponse
)

module.exports = router;