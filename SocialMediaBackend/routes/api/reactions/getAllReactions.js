const { reactions: reactionsMongo , users : usersMongo } = require("../../../db/mongo");
const getAllReactions = {};

getAllReactions.validateRequest = (req, res, next) => {
    const { entityId, entityType } = req.body;

    try {
        if (!entityId || !entityType) {
            return res.status(400).json({ message: "entityId and entityType are required." });
        }
        next();
    } catch (error) {
        console.error("Validation Error:", error.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

getAllReactions.fetchReactions = async (req, res, next) => {
    const { entityId, entityType } = req.body;

    try {
        const reactionsData = await reactionsMongo.instance.getReactionsByEntity(entityId, entityType);

        if (!reactionsData || Object.keys(reactionsData).length === 0) {
            return res.status(200).json({ success: true, message: "No reactions found.", reactions: [] });
        }

        req.reactionsData = reactionsData;
        next();
    } catch (error) {
        console.error("Error fetching reactions:", error.message);
        return res.status(500).json({ message: "Failed to fetch reactions." });
    }
};


getAllReactions.addUserDetails = async (req, res, next) => {
    try {
        const { reactionsData } = req;

        const userIds = [...new Set(Object.values(reactionsData).flatMap(reaction => reaction.users))];

        const userDetails = await usersMongo.instance.getUserShowingDetails(userIds);

        const userDetailsMap = userDetails.reduce((acc, user) => {
            acc[user.userId] = { name: user.name, profilePic: user.profilePic };
            return acc;
        }, {});

        const reactionsWithUsers = Object.entries(reactionsData).map(([reactionType, data]) => ({
            reactionType,
            count: data.count,
            users: data.users.map(userId => ({
                userId,
                name: userDetailsMap[userId]?.name || null,
                profilePic: userDetailsMap[userId]?.profilePic || null
            }))
        }));

        req.reactionsWithUsers = reactionsWithUsers;
        next();
    } catch (error) {
        console.error("Error adding user details:", error.message);
        return res.status(500).json({ message: "Failed to fetch user details." });
    }
};

getAllReactions.prepareReactionBlockFilter = (req, res, next) => {
    try {
        if (!req.reactionsWithUsers || !Array.isArray(req.reactionsWithUsers)) {
        return next();
        }
        const allUserIds = req.reactionsWithUsers.reduce((acc, reaction) => {
        reaction.users.forEach(user => {
            if (!acc.includes(user.userId)) {
            acc.push(user.userId);
            }
        });
        return acc;
        }, []);
        req._toBeFiltered = allUserIds; // This will be used by the block service middleware.
        next();
    } catch (error) {
        console.error("Error in prepareReactionBlockFilter:", error.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
    };

getAllReactions.filterOutBlockedReactionUsers = (req, res, next) => {
    try {
        const allowedUserIds = req.filteredAfterBlockCheckUserIds || [];
        req.reactionsWithUsers = req.reactionsWithUsers.map(reaction => {
        const filteredUsers = reaction.users.filter(user => allowedUserIds.includes(user.userId));
        return {
            ...reaction,
            count: filteredUsers.length,
            users: filteredUsers
        };
        });
        next();
    } catch (error) {
        console.error("Error filtering reaction users:", error.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
    };

getAllReactions.buildResponse = (req, res) => {
    return res.status(200).json({
        message: "Reactions fetched successfully.",
        reactions: req.reactionsWithUsers,
    });
};

module.exports = getAllReactions;
