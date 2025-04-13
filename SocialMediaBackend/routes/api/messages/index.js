const router = require("express").Router();
const auth = require('../auth')
const messageInteraction = require('./interaction')


router.post('/messages/interact',
    auth.validateUser,
    messageInteraction.validateBody,
    messageInteraction.saveToMongo
)

module.exports = router