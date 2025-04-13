const { feeds: feedsMongo ,reactions: reactionsMongo, followers : followersMongo, comments : commentsMongo , users : usersMongo } = require('../../../db/mongo');
const { FIELDS } = require('../../../db/mongo/followers');
const moment = require('moment');
const axios = require('axios');

const getHomePagePosts = {};

getHomePagePosts.getAllFollowings = async (req, res, next) => {
  const userId = req.userId;

  try {
    const followings = await followersMongo.instance.getFollowings(userId);
    const followingUserIds = followings.map(f => f[FIELDS.SENT_TO]);

    // if (!followingUserIds.length) {
    //   return res.status(200).json({ message: 'No followings found.', posts: [] });
    // }

    if (!followingUserIds.includes(userId)) {
      followingUserIds.push(userId);
    }

    // Fetch random public user IDs from users module.
    const randomPublicUserIds = await usersMongo.instance.getRandomPublicUserIds();
    const combinedUserIdsSet = new Set([...followingUserIds, ...randomPublicUserIds]);
    const combinedUserIds = Array.from(combinedUserIdsSet);

    req.followingUserIds = combinedUserIds;
    req._toBeFiltered = req.followingUserIds;
    next();
  } catch (err) {
    console.error('Error fetching followings:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

// First middleware - fetch posts from followings
getHomePagePosts.fetchPostsFromFollowings = async (req, res, next) => {
  const followingUserIds = req.filteredAfterBlockCheckUserIds;
  
  try {
    const posts = await feedsMongo.instance.getPostsByUserIds(followingUserIds);

    if (posts.length) {
      const followingPosts = posts
        .flatMap(userPosts => userPosts.posts.map(post => ({
          ...post,
          userId: userPosts.userId,
          ago_time: getTimeAgo(post.createdAt),
          isCommunity: false // Mark as non-community post
        })));

      req.followingPosts = followingPosts;
    } else {
      req.followingPosts = [];
    }
    
    next();
  } catch (err) {
    console.error('Error fetching following posts:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

// Second middleware - fetch community posts
getHomePagePosts.fetchPostsFromCommunities = async (req, res, next) => {
  try {
    // Get user's communities
    const userCommunities = await usersMongo.instance.getUserCommunities(req.userId);
    
    if (!userCommunities.length) {
      req.communityPosts = [];
      return next();
    }

    // Fetch community posts using the API endpoint
    const response = await axios.post(
      'https://bond-bridge-admin-dashboard.vercel.app/api/communities/postOfAllCommunities',
      { communityIds: userCommunities },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic Og=='
        }
      }
    );

    if (response.data.success && response.data.posts.length) {
      const communityPosts = response.data.posts.map(post => ({
        ...post,
        feedId: post._id, // Map _id to feedId for consistency
        userId: post.communityId, // Using communityId as userId for consistency
        ago_time: getTimeAgo(post.createdAt),
        isCommunity: true // Mark as community post
      }));
      
      req.communityPosts = communityPosts;
    } else {
      req.communityPosts = [];
    }
    
    next();
  } catch (err) {
    console.error('Error fetching community posts:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

// Final middleware - combine and shuffle posts
getHomePagePosts.combineAndProcessPosts = async (req, res, next) => {
  try {
    const allPosts = [...(req.followingPosts || []), ...(req.communityPosts || [])];
    
    if (!allPosts.length) {
      return res.status(404).json({ message: 'No posts found', posts: [] });
    }

    const shuffledPosts = allPosts.sort(() => Math.random() - 0.5);

    const postIds = shuffledPosts.map(post => post.feedId);
    
    //if change kroge toh baaki apis mein bhi , getAllPosts and getPostDetails
    const [commentCounts, reactionCounts, detailedReactions, userReactions] = await Promise.all([
      commentsMongo.instance.getCommentCountByPostId(postIds),
      reactionsMongo.instance.getReactionCountByPostId(postIds), // existing method
      reactionsMongo.instance.getDetailedReactionsByPostId(postIds), // new method
      reactionsMongo.instance.getUserReactionsOnPosts(req.userId, postIds) // new method
    ]);
    const userReactionsMap = userReactions.reduce((acc, reaction) => {
      acc[reaction.entity_id] = reaction;
      return acc;
    }, {});
    

    const postsWithActions = shuffledPosts.map(post => {
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

getHomePagePosts.addUserDetails = async (req, res, next) => {
  const { posts } = req;

  const userIds = [...new Set(
    posts
      .filter(post => post.isCommunity === false) // Only non-community posts
      .map(post => post.userId)
  )];

  try {
    const userDetails = await usersMongo.instance.getUserShowingDetails(userIds);

    const postsWithUserDetails = posts.map((post) => {
      const userDetail = userDetails.find((user) => String(user.userId) === post.userId) || {};
      return {
        ...post,
        name: userDetail.name || null,
        profilePic: userDetail.profilePic || null,
      };
    });

    req.posts = postsWithUserDetails; // Preserve order
    next();
  } catch (err) {
    console.error('Error adding user details:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

getHomePagePosts.buildResponse = (req, res) => {
  const { posts } = req;
  res.status(200).json({ message: 'Posts fetched successfully' , count : posts.length , posts});
};

function getTimeAgo(createdAt) {
  return moment.unix(createdAt).fromNow();
}
module.exports = getHomePagePosts;
