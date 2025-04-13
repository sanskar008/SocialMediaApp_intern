const { followers: followersMongo } = require("../../../db/mongo");
const { FIELDS } = require("../../../db/mongo/followers");
const { followNotification } = require("../../messages/");
const follower = {};

follower.validateSendOrCancelRequestBody = (req, res, next) => {
    const { sentTo } = req.body;

    if (!sentTo) return res.status(400).json({ message: 'Invalid JSON body' });
    next();
};

follower.validateAcceptRejectRemoveBody = (req, res, next) => {
    const { otherId: sentBy } = req.body;
    
    if (!sentBy) return res.status(400).json({ message: 'Invalid JSON body' });
    next();
};

follower.areRelated = async (req, res, next) => {
    const userId = req.userId;
    const { otherId } = req.body;

    try{
        const isRelated = await followersMongo.instance.isRelated(userId, [otherId], 1);
        if (!isRelated) {
            return res.status(400).json({success:false, message: "Users are not related" });
        }
        next();
    }
    catch{
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }

}

follower.checkFollowerAndRemove = async (req,res,next) => {
    const userId = req.userId;
    const {otherId } = req.body;

    try{
        const removeFollower = await followersMongo.instance.removeFollower(otherId, userId);

        return res.status(200).json({success :removeFollower})


    }
    catch{
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
}

follower.unfollow = async (req, res, next) => {
    const userId = req.userId;
    const { otherId } = req.body;

    try {
        const removedRequest = await followersMongo.instance.removeRequest({ sentBy: userId, sentTo: otherId },1);
        if (!removedRequest) {
            return res.status(404).json({ success: false,message: "Request not found" });
        }
        res.status(200).json({success: true,  message: "Request canceled successfully" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
}

follower.checkAlreadyExistingRequest = async (req, res, next) => {
    const userId = req.userId;
    const { sentTo } = req.body;

    try {

        if (userId === sentTo) {
            return res.status(400).json({ message: "Cant send Request to yourself." });
        }

        const existingRequest = await followersMongo.instance.requestsSentStatus(userId, [sentTo]);
        if (existingRequest && existingRequest.length) {
            return res.status(400).json({ message: "Request already exists" });
        }
        next();
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.sendRequest = async (req, res, next) => {
    const sentBy = req.userId;
    const { sentTo } = req.body;

    try {
        const request = await followersMongo.instance.saveRequest({ sentBy, sentTo });
        followNotification.send(senderId = sentBy,receiverId = sentTo)
        res.status(200).json({ message: "Request sent successfully", request });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.acceptRequest = async (req, res, next) => {
    const sentTo = req.userId;
    const { otherId: sentBy } = req.body;

    try {
        const updatedRequest = await followersMongo.instance.acceptFollowRequest({ sentBy, sentTo });
        if (!updatedRequest) {
            return res.status(404).json({ message: "Request not found" });
        }
        followNotification.accept(senderId  = sentTo,receiverId = sentBy)
        res.status(200).json({ message: "Request accepted successfully" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.cancelRequest = async (req, res, next) => {
    const sentBy = req.userId;
    const { sentTo } = req.body;

    try {
        const removedRequest = await followersMongo.instance.removeRequest({ sentBy, sentTo });
        if (!removedRequest || !removedRequest.value) {
            return res.status(404).json({ message: "Request not found" });
        }
        res.status(200).json({ message: "Request canceled successfully" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.rejectRequest = async (req, res, next) => {
    const sentTo = req.userId;
    const { otherId: sentBy } = req.body;

    try {
        const removedRequest = await followersMongo.instance.removeRequest({ sentBy, sentTo });
        if (!removedRequest) {
            return res.status(404).json({ message: "Request not found" });
        }
        res.status(200).json({ message: "Request rejected successfully" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.getPendingRequests = async (req, res, next) => {
    const userId = req.userId;
    const { page = 1, limit = 10 } = req.query;

    try {
        const requests = await followersMongo.instance.requests({ userId, page: parseInt(page), limit: parseInt(limit) });
        
        // Assuming `FIELDS.SENT_BY` holds the key to identify the user who sent the request
        const userMap = requests.map(request => ({ _id: request[FIELDS.SENT_BY] }));
        
        req._users = userMap;
        next()
        
        
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.getFollowers = async (req, res, next) => {
    const userId = req.userId;
    const { page = 1, limit = 10 } = req.query;

    try {
        const requests = await followersMongo.instance.getFollowers( userId);
        
        // Assuming `FIELDS.SENT_BY` holds the key to identify the user who sent the request
        const userMap = requests.map(request => ({ _id: request[FIELDS.SENT_BY] }));
        
        req._users = userMap;
        next()
        
        
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.getFollowings = async (req, res, next) => {
    const userId = req.userId;
    const { page = 1, limit = 10 } = req.query;

    try {
        const requests = await followersMongo.instance.getFollowings( userId);
        
        // Assuming `FIELDS.SENT_BY` holds the key to identify the user who sent the request
        const userMap = requests.map(request => ({ _id: request[FIELDS.SENT_TO] }));
        req._users = userMap;
        next()
        
        
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

follower.getFollowCounts = async (req, res, next) => {
    const userId = req.userId;

    try {
        const followersCount = await followersMongo.instance.followersCount(userId);
        const followingsCount = await followersMongo.instance.followingsCount(userId);
        res.status(200).json({ followersCount, followingsCount });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

module.exports = follower;
