//db
const { otp : userOtp, sso } = require('../../../db/redis');
const { users : usersMongo } = require('../../../db/mongo');
const { users : usersElastic } = require('../../../db/elastic');
const { FIELD_VALUES : USER_FIELD_VALUES , FIELDS : USER_FIELDS } = require('../../../db/mongo/users');
//service
const { sendOtpViaTwilio } = require('./service');
//libraries
const crypto = require('crypto');
const { users : userRedis } = require('../../../db/redis');
const ssoHelper = require('../sso');
const nickNameGenerator = require('./nickName');

//default avatar URL face5.png of male
defaultAvatarUrl = "https://media-servicetesting.s3.amazonaws.com/maleAvatars/6782b049398b8c76879dece7/face5.png";

const MAX_REQUESTS = 3;

const otp = {};


otp.validateBody =  (req, res, next) => {
    const { phoneNumber, countryCode } = req.body;
   
    //validation
    if (!phoneNumber && !countryCode) {
        return res.status(400).json({ message: 'Phone number and country code are required.' });
    } else if (!phoneNumber) {
        return res.status(400).json({ message: 'Phone number is required.' });
    } else if (!countryCode) {
        return res.status(400).json({ message: 'Country code is required.' });
    }
    
    next();
}


otp.checkStatus = async (req , res , next) => {
    try{
        const { phoneNumber, countryCode } = req.body;
        const forgot = ('forgot' in req.body) ? true : false;
        const userExists = await usersMongo.instance.checkIfUserExists(phoneNumber, countryCode); //this one is used for mongo

        if ( userExists && !forgot){ //it means if forgot hoga ,toh ise nahi dekhenge
            return res.status(409).json({message: 'User already exists. Please log in instead.'});
        }
        if ( !userExists && forgot ){ //if user exist hi nhi krta , aur forgot krne agya haraamzada
            return res.status(404).json({message: 'User Does not exists'});
        }

        const result = await userOtp.getOtpInfo(phoneNumber , countryCode);
        if ( result ){
            return res.status(400).json({message : `OTP already sent. Please try again in a minute.`})
        }
        next();
    }
    catch(err){
        console.log(err);
    }
}

otp.checkCount = async(req,res,next) => {
    const { phoneNumber, countryCode } = req.body;

    const currentCount = await userOtp.getRequestCount(phoneNumber , countryCode);

    if ( currentCount ){
        if ( currentCount >= MAX_REQUESTS ){
            return res.status(429).json( {message: 'Maximum OTP requests reached. Please try again after 15 minutes.' });

        }
        await userOtp.setRequestCount(phoneNumber , countryCode , currentCount);
        return next();
    }
    await userOtp.setRequestCount(phoneNumber , countryCode , 0);
    next();
}

otp.generateOtp = async(req, res, next) => {
    const otp = crypto.randomInt(100000, 999999); // Generate 6-digit OTP
    req._otp = otp;
    next();
}
otp.sendOtp = async (req, res, next) => {
    const { phoneNumber, countryCode } = req.body;

    try {
        const otp = req._otp;
        await userOtp.setOtp(phoneNumber, countryCode, otp);

        //twilio
        const twilioResponse = await sendOtpViaTwilio(phoneNumber , countryCode , otp);

        return res.status(200).json({ message: 'OTP sent successfully.', otp }); // Include OTP for testing
    } catch (err) {
        console.error('Error sending OTP via Twilio:', err.message);
        return next({ status: 500, message: 'Failed to send OTP. Please try again later.' });
    }
};

otp.validateVerifyBody =  (req, res, next) => {
    const { countryCode, phoneNumber, otp } = req.body;

    if (!phoneNumber && !otp && !countryCode) {
        return res.status(400).json({ message: 'Phone number, Country code, and OTP are required.' });
    } else if (!phoneNumber) {
        return res.status(400).json({ message: 'Phone number is required.' });
    } else if (!otp) {
        return res.status(400).json({ message: 'OTP is required.' });
    } else if (!countryCode) {
        return res.status(400).json({ message: 'Country Code is required.' });
    }
    

    next();
}

// Route to verify OTP
otp.verifyOtp =  async (req, res, next) => {
    const { countryCode, phoneNumber, otp } = req.body;
    const forgot = ('forgot' in req.body) ? true : false;

    try {
        const storedOtp = await userOtp.getOtpInfo( phoneNumber , countryCode );

        if (!storedOtp) {
            // No OTP exists or it has expired
            return res.status(400).json( {  message: 'OTP has expired' });
        }

        if (storedOtp !== otp) {
            // Incorrect OTP
            return res.status(400).json( { message: 'Invalid OTP. Please try again.' });
        }

        if ( forgot ){
            return res.status(200).json({message : 'OTP verified ! You can set your password'})
        }

        next();
    } catch (err) {
        next(err);
    }
};

otp.addUserToDB = async(req,res,next) => {
    const { countryCode, phoneNumber } = req.body;

    //if user not already exists
    const userExists = await usersMongo.instance.checkIfUserExists(phoneNumber, countryCode); //this one is used for mongo
    if ( userExists ){
        return res.status(409).json({message: 'User already exists. Please log in instead.'});
    }
    const userDetails = {
        [USER_FIELDS.MOBILE] : phoneNumber ,
        [USER_FIELDS.COUNTRY_CODE] : countryCode,
        [USER_FIELDS.NICKNAME] : await nickNameGenerator(),
        [USER_FIELDS.STATUS_CODE] : USER_FIELD_VALUES[USER_FIELDS.STATUS_CODE].ON_BOARDED,
        [USER_FIELDS.PRIVACY_LEVEL] : 0,
        [USER_FIELDS.AVATAR] : defaultAvatarUrl,
        [USER_FIELDS.PUBLIC] : 1
    };            

    const userId = await usersMongo.instance.createUser(userDetails)
    await usersElastic.instance.addUser(userId , userDetails);
    req.userId = userId
    req.profile = userDetails
    const data = await usersElastic.instance.getAllUsers();
    await userRedis.addUser(userId , userDetails);
    return next();
}

otp.generateSSO = async(req,res,next) => {
    const { userId } = req;

    const token = await ssoHelper.generateAndSave(userId);

    return res.status(200).json({message : "Your OTP was Verified! Thanks for joining" , userDetails : req.profile, token: token});


}

module.exports = otp;
