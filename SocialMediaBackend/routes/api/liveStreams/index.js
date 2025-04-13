const express = require("express");
const router = express.Router();
const auth = require('../auth')
const liveStream = require("./liveStream");

router.post("/start-live-stream",
    auth.validateUser,
    liveStream.validateStartLiveBody, 
    liveStream.startLiveStream
);

router.post("/end-live-stream", 
    auth.validateUser,
    liveStream.validateEndLiveBody, 
    liveStream.endLiveStream
);

router.post("/join-live-stream", 
    auth.validateUser,
    liveStream.validateJoinLiveBody,
    liveStream.checkLiveStreamStatus,
    liveStream.generateTokenForLiveStream
);

module.exports = router;
