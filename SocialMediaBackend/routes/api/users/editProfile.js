const { users : usersMongo } = require('../../../db/mongo');
const { FIELDS : USER_FIELDS , FIELD_VALUES : USER_FIELD_VALUES } = require('../../../db/mongo/users');
const {users : userRedis} = require('../../../db/redis');
const {users : usersElastic} = require('../../../db/elastic')

const ssoHelper = require('../sso');
const jwt = require('jsonwebtoken');

const EDIT_PROFILE_FIELDS = {
    NAME: 'name',
    EMAIL: 'email',
    PROFILE_PIC: 'profilePic',
    STATUS: 'status',
    FCM_TOKEN: 'fcmToken',
    COUNTRY_CODE: 'countryCode',
    INTERESTS: 'interests',
    ADDRESS: 'address',
    PRIVACY_LEVEL : 'privacyLevel',
    AVATAR : 'avatar',
    BIO : 'bio',
    DOB : 'dob',
    PUBLIC : 'public'
};

const COMMUNITY_ACTION_FIELDS = {
    JOIN : 'join',
    REMOVE : 'remove'
}

const editProfile = {};

editProfile.validateRequestBody = (req, res, next) => {
    const updates = req.body;
    
    if(updates[EDIT_PROFILE_FIELDS.INTERESTS]) updates[EDIT_PROFILE_FIELDS.INTERESTS] = JSON.parse(updates[EDIT_PROFILE_FIELDS.INTERESTS]);


    // Check if the body is empty
    if ((!updates || Object.keys(updates).length === 0) && !req.files) {
        return res.status(400).json({ message: 'Request body cannot be empty. Please provide fields to update.' });
    }

    // Check if updates contain valid fields
    const validFields = Object.values(EDIT_PROFILE_FIELDS);  // Get the valid field names from the values of EDIT_PROFILE_FIELDS
    const invalidFields = Object.keys(updates).filter(field => !validFields.includes(field)); // Check if fields are not in validFields
    if (invalidFields.length > 0) {
        return res.status(400).json({ message: `Invalid fields provided: ${invalidFields.join(', ')}` });
    }

    // Check if 'interests' is an array
    if (updates[EDIT_PROFILE_FIELDS.INTERESTS] && !Array.isArray(updates[EDIT_PROFILE_FIELDS.INTERESTS])) {
        return res.status(400).json({ message: 'Interests must be an array.' });
    }

    //privacy level
    if (EDIT_PROFILE_FIELDS.PRIVACY_LEVEL in updates) {
        const privacyLevel = parseInt(updates[EDIT_PROFILE_FIELDS.PRIVACY_LEVEL], 10);
        if (privacyLevel !== 0 && privacyLevel !== 1) {
            return res.status(400).json({ message: "Invalid privacyLevel. It must be 0 or 1." });
        }
    }

    // public flag
    if (EDIT_PROFILE_FIELDS.PUBLIC in updates) {
        const publicFlag = parseInt(updates[EDIT_PROFILE_FIELDS.PUBLIC], 10);
        if (publicFlag !== 0 && publicFlag !== 1) {
            return res.status(400).json({ message: "Invalid public value. It must be 0 or 1." });
        }
        updates[EDIT_PROFILE_FIELDS.PUBLIC] = publicFlag;
    }

    req.body.entityType = 'user';
    req.updates = updates; 
    next();
};


editProfile.updateProfile = async (req, res, next) => {
    const { userId } = req; //same as req.userId
    const updates = req.updates;

    try {

        //updating the status code to , all set

        updates[USER_FIELDS.STATUS_CODE] = USER_FIELD_VALUES[USER_FIELDS.STATUS_CODE].PROFILE_SET;
        if(req.files && req.files.image) updates[USER_FIELDS.PROFILE_PIC] = req?._media[0]?.url;
        // Update the user details in mongo
        const updateResult = await usersMongo.instance.updateUser(userId, updates);
        //update in elastic too
        await usersElastic.instance.updateUser(userId , updates)
        
        if (!updateResult) {
            return res.status(404).json({ message: 'User not found.' });
        }   
        
        //update the user details in redis
        await userRedis.addUser(userId , updateResult);

        req._userDetails = updateResult;
        next();
    } catch (err) {
        console.error('Error updating user profile:', err.message);
        next({ status: 500, message: 'Internal Server Error' });
    }
};

editProfile.manageToken = async (req, res , next) => {
    const { generateToken } = req.query;
    const { userId } = req;
    try{
        if ( generateToken && generateToken === "1" ){
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
        }
        next();
    }
    catch(err){
        console.error('Error Generating Tokens:', err.message);
        next({ status: 500, message: 'Internal Server Error' });
    }
}

editProfile.buildResponse = async (req, res) => {
    const { generateToken } = req.query;
    const { _userDetails : userDetails,
            _socketToken : socketToken,
            _apiToken : apiToken
            } = req;

    try{
        if ( generateToken && generateToken === "1" ){
            return res.status(200).json({message : "Profile updated successfully." , userDetails , apiToken , socketToken });
        }
        return res.status(200).json({message : "Profile updated successfully." , userDetails});
    }
    catch(err){
        console.error('Error Generating Response:', err.message);
        next({ status: 500, message: 'Internal Server Error' });
    }
}


editProfile.joinCommunity = async(req,res,next) => {
    const userId  = req.userId

    const {communityId , action } = req.body;
    if(!action || !communityId) return res.status(400).json({success:false, message:'Missing JSON Body'})

    if(!Object.values(COMMUNITY_ACTION_FIELDS).includes(action)) return res.status(400).json({success:false , message : 'Action must be join/remove only'});

    try{
        const updateResult = await usersMongo.instance.joinCommunity(userId, {communityId : communityId, action: action});
        return res.status(200).json({success:true ,message:'Action Performed Successfully'})
    }
    catch(err){
        return res.status(400).json({success:false,message:'Some Error Occurred'})
    }


}

module.exports = editProfile;
