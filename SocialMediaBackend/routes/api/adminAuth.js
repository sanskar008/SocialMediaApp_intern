const auth = {}
const moment = require('moment')
const { users: userRedis } = require('../../db/redis');
const ssoHelper = require('./sso')
require('dotenv').config();

auth.validateUser = async (req, res, next) => {
    const ip = getClientIp(req);
    console.log(`[${moment().format("YYYY-MM-DD hh:mm:ss")}] [${ip}]`, "URL & PARAMS", req.originalUrl, req.query, req.headers["userid"] || {}, req.method,req.body);  


    const { userid , token } = req.headers;
    
    // if (!userid || !token) {
    if (!userid) {
        return res.status(401).json({ message: "Unauthorised" });
    }
   
    req.userId = userid;
    const admins = process.env.ADMIN.split(",");
    console.log(admins);

    if (!admins.includes(userid)) {
        return res.status(403).json({ message: "Forbidden: Check UserId" });
    }
    
    try {
        const userDetails = await userRedis.getUserDetails(userid);

        if (!userDetails || Object.keys(JSON.parse(userDetails)).length === 0) {
            return res.status(400).json({ message: "Admin doesn't exist" });
        }

        if(req.query.other){
            req.otherProfile = JSON.parse(await userRedis.getUserDetails(req.query.other));
        }
        return next();
        /*
        const isVerified = await ssoHelper.verify(token,userid);

        if(!isVerified && token!= "aryan") return res.status(401).json({ message: "Unauthorised" });
        
        req.profile = userDetails;

        next();*/
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
  