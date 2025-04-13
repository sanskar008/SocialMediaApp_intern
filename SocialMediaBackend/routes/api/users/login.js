const bcrypt = require('bcryptjs'); // for password hashing
const { users: usersMongo } = require('../../../db/mongo');
const { users: userRedis } = require('../../../db/redis');
const ssoHelper = require('../sso');
const jwt = require('jsonwebtoken');

const {FIELDS : USER_FIELDS} = require('../../../db/mongo/users')

const login = {};

//PRE LOGIN

login.preLoginValidateRequestBody = (req, res, next) => {
    const { phoneNumber, countryCode } = req.body;

    try {
        if (!phoneNumber || !countryCode) {
            return res.status(400).json({ message: 'Phone number and country code are required.' });
        }

        next(); // Proceed to the next step
    } catch (err) {
        console.error('Error in preLoginValidateRequestBody:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}

login.preLoginSendStatusCode = async (req, res, next) => {
    const { phoneNumber, countryCode } = req.body;

    try {
        // Fetch user details
        const userDetails = await usersMongo.instance.getUserDetailsFromMobile(phoneNumber, countryCode);

        if (!userDetails) {
            return res.status(404).json({ message: 'User not found. Please Sign up' });
        }

        const STATUS_CODE = userDetails[USER_FIELDS.STATUS_CODE];

        return res.status(200).json({ STATUS_CODE: STATUS_CODE });
    } catch (err) {
        console.error('Error in preLoginSendStatusCode:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
}

//LOGIN

// Validate the login request body (check if phone number, country code, and password are provided)
login.validateRequestBody = (req, res, next) => {
    const { password, phoneNumber, countryCode } = req.body;

    // Check if password is provided
    if (!password) {
        return res.status(400).json({ message: 'Password is required.' });
    }

    // Check if phone number and country code are provided
    if (!phoneNumber || !countryCode) {
        return res.status(400).json({ message: 'Phone number and country code are required.' });
    }

    next(); // Proceed to the next step
};

// Get the user details from MongoDB and Redis
login.getUserDetailsFromDB = async (req, res, next) => {
    const { phoneNumber, countryCode } = req.body;

    try {
        // Step 1: Get the userId from MongoDB using phoneNumber and countryCode
        const userDetails = await usersMongo.instance.getUserDetailsFromMobile(phoneNumber, countryCode);

        if (!userDetails) {
            return res.status(404).json({ message: 'User not found.' });
        }

        req.profile = userDetails;

        next(); // Proceed to the next step (password verification)
    } catch (err) {
        console.error('Error fetching user details:', err);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

// Verify the password using bcrypt
login.verifyPassword = async (req, res ,next) => {
    const { password } = req.body;
    const { password: storedPassword } = req.profile;  // Password from Redis (hashed)

    try {
        const isMatch = await bcrypt.compare(password, storedPassword); // Compare hashed password

        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials.' });
        }

        next();
    } catch (err) {
        console.error('Error verifying password:', err);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

login.generateAndSaveTokens = async (req, res , next) => {

    const userId = req.profile._id;

    try {

        //apiToken
        const token = await ssoHelper.generateAndSave(userId);

        //socketToken payload
        const secret = process.env.JWT_CHAT_SECRET;
        const status = req.profile.statusCode;
        const payload = { id: userId, status : status, token :token }
        
        //socketToken generation
        const socketToken = jwt.sign(payload, secret, { algorithm: 'HS256' });
        
        //socketToken saving in redis
        await ssoHelper.saveSockeToken(socketToken , userId);

        req._socketToken = socketToken;
        req._apiToken = token;
        next();
    } catch (err) {
        console.error('Error generating Tokens: ', err);
        return res.status(500).json({ message: 'Internal server error' });
    }
};

login.buildResponse = async ( req,res ) =>{
    return res.status(200).json({
        message: 'Login successful',
        userDetails: req.profile,
        token : req._apiToken,
        socketToken : req._socketToken
    });
}


module.exports = login;
