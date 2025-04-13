const { followers : followersMongo } = require('../../../db/mongo');

const relationship = {};

relationship.buildRelation = async (req, res,next) => {
    const selfId = req.userId;
    const { _users } = req;

    const allUserIds = _users.map(user => user._id || user.id); // Elasticsearch se search(id) and relation builder(_id)
    try {
        const [isFollowing, isFollower, requestPending, requestSent] = await Promise.all([
            followersMongo.instance.isFollowing(selfId, allUserIds),
            followersMongo.instance.isFollower(allUserIds, selfId),
            followersMongo.instance.requestsPendingStatus(selfId, allUserIds),
            followersMongo.instance.requestsSentStatus(selfId, allUserIds)
        ]);

        const combinedUsers = _users.map((user, index) => ({
            ...user,
            isFollowing: isFollowing.includes(user._id),
            isFollower: isFollower.includes(user._id),
            requestPending: requestPending.includes(user._id),
            requestSent: requestSent.includes(user._id)
        }));
        
        req._users = combinedUsers;

        req._response = {
            result: combinedUsers,
            message: 'User details fetched successfully'
        }

        return next();
    } catch (error) {
        console.error('Error building relationships:', error);
        return res.status(500).json({
            error: 'Internal server error while fetching user relationships'
        });
    }
};


relationship.sendResponse = (req,res,next) => {
    return res.status(200).json(req?._response);
}



module.exports = relationship;
