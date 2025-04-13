const { users : userMongo, followers : followersMongo } = require('../../../db/mongo');
const user = require('../../../db/redis/users');
const axios = require('axios');
require('dotenv').config();

const showProfile = {}

showProfile.validateBody = (req,res,next) => {
    const { other } = req.query;

    if(!other) return res.status(400).json({message: 'Invalid JSON body'})
    next();
}

showProfile.fetchUserDetails = async(req,res,next) => {
    const userId = req.query.other;
    const selfId = req.userId;

    const userDetails = await userMongo.instance.getUserDetailsFromId(userId);
    const currentUser = await userMongo.instance.getUserDetailsFromId(selfId);
    const followersCount = await followersMongo.instance.followersCount(userId);
    const followingsCount = await followersMongo.instance.followingsCount(userId);
    
    if (userDetails && currentUser) {

        const compatibilityScore = calculateCompatibilityScore(currentUser, userDetails);
        
        const profileObject ={
            ...req.otherProfile,
            "name": userDetails.name,
            "email": userDetails.email,
            "profilePic": userDetails.profilePic,
            "mobile": userDetails.mobile,
            "email": userDetails.email,
            "followers": followersCount,
            "followings": followingsCount,
            "compatibility": compatibilityScore,
            "interests": userDetails.interests || [],
            "communities" : userDetails.communities || []
    
            
        }
        req._users = [profileObject]
        next()

    }
    else{
        return res.status(404).json({message: 'User not found'})
    }

}

showProfile.showUserDetails = async(req, res) => {
    const { _users } = req;

    const userDetails = await Promise.all(_users.map(async user => {
        return await userMongo.instance.getUserDetailsFromId(user._id);;
    }));

    return res.status(200).json({
        result: userDetails,
        message: 'User details fetched successfully'
    });
}

const calculateCompatibilityScore = (currentUser, otherUser) => {
    const weight = 1;
    let compatibilityScore = 0;

    if (!currentUser.interests || !otherUser.interests) return 0;

    // Finding common interests
    const commonInterests = currentUser.interests.filter(interest => 
        otherUser.interests.includes(interest)
    );

    compatibilityScore = commonInterests.length * weight;

    // Normalize score based on the maximum number of interests between the two users
    const maxInterests = Math.max(currentUser.interests.length, otherUser.interests.length);
    const finalPercentage = maxInterests > 0 ? ((compatibilityScore / maxInterests) * 100).toFixed(0) : 0;

    return finalPercentage;
};

showProfile.getAllUsers = async(req, res) => {
    try {
        const currentUserId = req.userId;

        const currentUser = await userMongo.instance.getUserDetailsFromId(currentUserId);
        if (!currentUser) {
            return res.status(404).json({ message: "User not found" });
        }

        const currentUserInterests = currentUser.interests.map(interest => interest.toLowerCase());
        // console.log("Current User Interests:", currentUserInterests);

    
    let users = await userMongo.instance.getUsersWithSharedInterests(currentUserId, currentUserInterests);

    res.status(200).json({ users });
    } catch (error) {
        console.error("Error fetching users:", error);
        res.status(500).json({ message: "Server error" });
    }
}

showProfile.getRandomText = async(req, res) => {

    try {
        const currentUserId = req.userId;
        const secondUserId = req.query.other;

        const secondUser = await userMongo.instance.getUserDetailsFromId(secondUserId);
        const currentUser = await userMongo.instance.getUserDetailsFromId(currentUserId);
        if (!currentUser || !secondUser) {
            return res.status(404).json({ message: "User not found" });
        }

        const currentUserInterests = currentUser.interests?.join(", ");
        const secondUserInterests = secondUser.interests?.join(", ");

        const prompt = `Generate a fun and engaging conversation starter:
        - ${currentUser.name} is interested in ${currentUserInterests}.
        - ${secondUser.name} is interested in ${secondUserInterests}.
        Suggest 2 or 3 random one liner starter message ${currentUser.name} can share to start the conversation. It should be short and consized , like 7-8 words per line`;

        // Call OpenAI API
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
              model: "gpt-3.5-turbo",
              messages: [
                { role: "system", content: prompt }
              ],
              max_tokens: 100,
            },
            {
              headers: {
                Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                "Content-Type": "application/json",
              },
            }
          );

        if (!response.data.choices || response.data.choices.length === 0) {
            throw new Error("Invalid API response: No choices returned.");
        }

        const conversationStarter = response.data.choices[0]?.message?.content?.trim();
        
        if (!conversationStarter) {
            throw new Error("Invalid API response: Content missing.");
        }

        res.json({ topic: conversationStarter });

    } catch (error) {
        console.error("Error fetching users or generating conversation", error);
        res.status(500).json({ message: "Server error" });
    }
}
  

module.exports = showProfile;