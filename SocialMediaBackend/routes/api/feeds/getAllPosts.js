const { feeds: feedsMongo ,reactions: reactionsMongo, followers : followersMongo, comments : commentsMongo , users : usersMongo } = require('../../../db/mongo');


const getAllPosts = {};

getAllPosts.validateRequest = (req, res, next) => {
    let { userId } = req; 
    if (req.query.userId ){
      req.appUser = req.userId;
      req.userId = req.query.userId;
    } //if some other userS post wanna see
    if (!userId) {
        return res.status(400).json({ message: 'User ID is required.' });
    }

    next();
};

getAllPosts.checkUserPostVisibility = async (req, res, next) => {
    if (!req.appUser || req.appUser === req.userId) {
        return next();
    }
    
    const requesterId = req.appUser;    
    const targetUserId = req.userId;     

    try {
        const targetUserDetails = await usersMongo.instance.getUserDetailsFromId(targetUserId);
        if (!targetUserDetails) {
            return res.status(404).json({ message: "User not found." });
        }

        // Agar target user ka profile public hai, allow karo.
        if (targetUserDetails.public === 1) {
            return next();
        }

        // Private profile case: ab connection check karo
        // Check if the requester is following the target user.
        const following = await followersMongo.instance.isFollowing(requesterId, [targetUserId]);
        // Check if the target user is following the requester.
        const follower = await followersMongo.instance.isFollower([targetUserId], requesterId);

        if ((following && following.length > 0) || (follower && follower.length > 0)) {
            return next();
        }

        return res.status(403).json({ message: "This user's posts are private." });
    } catch (err) {
        console.error("Error in checkUserPostVisibility:", err.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};


getAllPosts.fetchPostsFromMongo = async (req, res, next) => {
    const { userId } = req;
    try {
        const posts = await feedsMongo.instance.getAllPostsByUserId(userId);

        if (!posts.length) {
            return res.status(200).json({ message: 'No posts found for this user.' , posts});
        }

        req.posts = posts; 
        next(); 
    } catch (err) {
        console.error('Error fetching posts:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

getAllPosts.addPostActions = async (req, res, next) => {
    const { posts } = req;
  
    try {

      if (!posts.length) {
        return res.status(404).json({ message: 'No posts found', posts: [] });
      }
  
      const postIds = posts.map(post => post.feedId);
  
      const [commentCounts, reactionCounts, detailedReactions, userReactions] = await Promise.all([
        commentsMongo.instance.getCommentCountByPostId(postIds),
        reactionsMongo.instance.getReactionCountByPostId(postIds),
        reactionsMongo.instance.getDetailedReactionsByPostId(postIds),
        reactionsMongo.instance.getUserReactionsOnPosts(req.appUser != null ? req.appUser : req.userId, postIds)
      ]);
      const userReactionsMap = userReactions.reduce((acc, reaction) => {
        acc[reaction.entity_id] = reaction;
        return acc;
      }, {});
      
  
      const postsWithActions = posts.map(post => {
        const reactionDetail = detailedReactions[post.feedId] || { total: 0, types: {} };
        const userReaction = userReactionsMap[post.feedId];
  
        return {
          ...post,
          commentCount: commentCounts[post.feedId] || 0,
          reactionCount: reactionCounts[post.feedId] || 0,
          reactionDetails: {
            total: reactionDetail.total,
            types: reactionDetail.types
          },
          reaction: {
            hasReacted: !!userReaction,
            reactionType: userReaction ? userReaction.reaction_type : null,
          }
        };
      });
      req.posts = postsWithActions;
      next();
  
    } catch (err) {
      console.error('Error processing posts:', err.message);
      return res.status(500).json({ message: 'Internal Server Error' });
    }
  };


  getAllPosts.addUserDetails = async (req, res, next) => {
    const { posts } = req;
    const userIds = [...new Set(posts.map((post) => post.author))]; // Collect unique user IDs
  
    try {
      const userDetails = await usersMongo.instance.getUserShowingDetails(userIds);
  
      const postsWithUserDetails = posts.map((post) => {
        const userDetail = userDetails.find((user) => String(user.userId) === String(post.author)) || {};
        return {
          ...post,
          name: userDetail.name || null,
          profilePic: userDetail.profilePic || null,
        };
      });
  
      req.posts = postsWithUserDetails;
      next();
    } catch (err) {
      console.error("Error adding user details:", err.message);
      return res.status(500).json({ message: "Internal Server Error" });
    }
  };

getAllPosts.buildResponse = (req, res) => {
    const { posts } = req;
    res.status(200).json({ message: 'Posts fetched successfully', posts });
};

module.exports = getAllPosts;
