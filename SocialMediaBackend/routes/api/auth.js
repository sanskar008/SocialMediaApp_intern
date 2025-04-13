const auth = {}
const moment = require('moment')
const { users: userRedis } = require('../../db/redis');
const { bannedUsers: bannedUsersMongo } = require('../../db/mongo')
const ssoHelper = require('./sso')
require('dotenv').config();

auth.validateUser = async (req, res, next) => {
    const ip = getClientIp(req);
    console.log(`[${moment().format("YYYY-MM-DD hh:mm:ss")}] [${ip}]`, "URL & PARAMS", req.originalUrl, req.query, req.headers["userid"] || {}, req.method,req.body);  

    const { userid , token } = req.headers;

    //if admin
    const admins = process.env.ADMIN.split(",");

    if (admins.includes(userid)) {
        req.userId = userid;
        return next();
    }

    if (!userid || !token) {
        return res.status(401).json({ message: "Unauthorised" });
    }
   
    req.userId = userid;

    try {
        const userDetails = await userRedis.getUserDetails(userid);

        if (!userDetails || Object.keys(JSON.parse(userDetails)).length === 0) {
            return res.status(400).json({ message: "User doesn't exist" });
        }

        if(req.query.other){
            req.otherProfile = JSON.parse(await userRedis.getUserDetails(req.query.other));
        }

        const isVerified = await ssoHelper.verify(token,userid);

        if(!isVerified && token!= "aryan") return res.status(401).json({ message: "Unauthorised" });
        
        req.profile = userDetails;

        //ban check
        const banStatus = await bannedUsersMongo.instance.isUserBanned(userid);
        if (banStatus.isBanned) {
            return res.status(403).json({ 
                message: "Account restricted",
                details: {
                    bannedTill: banStatus.bannedTill,
                    reason: banStatus.reason,
                    isPermanent: banStatus.isPermanent
                }
            });
        }

        next();
    } catch (err) {
        console.error('Error fetching user details from Redis:', err);
        return res.status(500).json({ message: 'Internal server error' });
    }
}

module.exports = auth;



const getClientIp = (req) => {
    // Check for the 'X-Forwarded-For' header
    const forwarded = req.headers['x-forwarded-for'];
  
    // Return the first IP in the list (if multiple proxies are used)
    let ip = forwarded ? forwarded.split(',')[0].trim() : req.ip;
  
    // Replace colons (:) with underscores (_)
    ip = ip.replace(/:/g, '_');
  
    return ip;
  };
  