const express = require('express');
const router = express.Router();
const otp = require("./otp")

router.post("/send-otp" , 
    otp.validateBody,
    otp.checkStatus,
    otp.checkCount,
    otp.generateOtp,
    otp.sendOtp
)
router.post("/verify-otp",
    otp.validateVerifyBody,
    otp.verifyOtp,
    otp.addUserToDB,
    otp.generateSSO
)
module.exports = router