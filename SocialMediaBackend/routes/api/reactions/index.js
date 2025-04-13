const express = require('express');
const { reactions } = require('../../../db/mongo');
const auth = require('../auth');
const addReaction = require("./add");
const deleteReaction = require('./delete');
const getAllReactions = require('./getAllReactions');
const blockService = require('../blockService');

const router = express.Router();

router.post('/reaction', 
    auth.validateUser,
    addReaction.validateBody,
    addReaction.checkEntityType,
    addReaction.postReaction,
    addReaction.buildResponse
);

router.delete('/reaction',
    auth.validateUser,
    deleteReaction.validateBody,
    deleteReaction.checkEntityType,
    deleteReaction.fromMongo,
    deleteReaction.buildResponse
);

router.post('/get-all-reactions',
    auth.validateUser,
    getAllReactions.validateRequest,
    getAllReactions.fetchReactions,
    getAllReactions.addUserDetails,
    getAllReactions.prepareReactionBlockFilter,
    blockService.filterBlockIdsMiddleware,
    getAllReactions.filterOutBlockedReactionUsers,
    getAllReactions.buildResponse
);

module.exports = router;
