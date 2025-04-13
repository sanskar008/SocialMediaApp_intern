const express = require('express');
const router = express.Router();
const auth = require("../auth");
const startCall = require('./startCall');
const acceptCall = require('./acceptCall');
const updateCallStatus = require('./updateCallStatus');

// Routes
router.post('/start-call',
    auth.validateUser,    
    startCall.validateBody,
    startCall.checkCallStatus,
    startCall.fetchParticipants,
    startCall.generateChannelName,
    startCall.initiateCall,
    startCall.notifyUsers
);

router.post('/accept-call',
    auth.validateUser,
    acceptCall.validateBody,
    acceptCall.validateCall,
    acceptCall.acceptCall
);

router.post('/update-call-status',
    auth.validateUser,
    updateCallStatus.validateBody,
    updateCallStatus.update
);

module.exports = router;
