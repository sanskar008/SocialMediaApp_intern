const { feeds: feedsMongo , users: usersMongo , comments: commentsMongo , reactions: reactionsMongo, followers : followersMongo } = require('../../../db/mongo');
const {FIELDS, FIELDS_VALUES} = require("../../../db/mongo/feeds")
const moment = require('moment');

const getPostDetails = {};

getPostDetails.validateRequest = (req, res, next) => {
  const { feedId } = req.query;
  if (!feedId) {
    return res.status(400).json({ message: 'feedId query parameter is required' });
  }
  next();
};

getPostDetails.fetchPost = async (req, res, next) => {
  const { feedId } = req.query;
  const userId = req.userId;
  try {
    const feedInstance = await feedsMongo.forId(feedId);
    const post = await feedInstance.getPostById(feedId);
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    // Check privacy settings
    if (post[FIELDS.PRIVACY] === FIELDS_VALUES[FIELDS.PRIVACY].NO_ONE) {
      return res.status(404).json({ message: 'Private post permission denied' });
    }

    // Check if post is private to specific users
    if (post[FIELDS.PRIVATE_TO] && Array.isArray(post[FIELDS.PRIVATE_TO]) && post[FIELDS.PRIVATE_TO].length > 0) {
      if (!post[FIELDS.PRIVATE_TO].includes(userId) && post[FIELDS.AUTHOR] !== userId) {
        return res.status(404).json({ message: 'Private post permission denied' });
      }
    }

    // Check if user is in hideFrom list
    if (post[FIELDS.HIDE_FROM] && Array.isArray(post[FIELDS.HIDE_FROM]) && post[FIELDS.HIDE_FROM].includes(userId)) {
      return res.status(404).json({ message: 'Post is hidden from you' });
    }

    req.body.otherId = post[FIELDS.AUTHOR]
    req.post = post;
    next();
  } catch (err) {
    console.error('Error fetching post:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

getPostDetails.addAuthorDetails = async (req, res, next) => {
    const { post } = req;
    try {
      const userDetails = await usersMongo.instance.getUserShowingDetails([post.author]);
      post.authorDetails = userDetails[0] || {};
      next();
    } catch (err) {
      console.error('Error adding author details:', err.message);
      return res.status(500).json({ message: 'Internal Server Error' });
    }
};

getPostDetails.checkPostVisibility = async (req, res, next) => {
  const { post } = req;
  const userId = req.userId;  // requester ID
  
  // Agar post owner same hai as logged in user, koi additional check ki zarurat nahi
  if (post[FIELDS.AUTHOR] === userId) {
    return next();
  }
  
  const authorDetails = await usersMongo.instance.getUserDetailsFromId(post.author);
  if (authorDetails && authorDetails.public === 1) {
    return next();
  }

  try {
    // Check if current user is following the author
    const following = await followersMongo.instance.isFollowing(userId, [post[FIELDS.AUTHOR]]);
    // Check if author is following the current user
    const follower = await followersMongo.instance.isFollower([post[FIELDS.AUTHOR]], userId);
    
    if ((following && following.length > 0) || (follower && follower.length > 0)) {
      return next();
    }
    
    return res.status(403).json({ message: "You are not allowed to view this post." });
  } catch (err) {
    console.error("Error in checkPostVisibility:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};


getPostDetails.addCommentAndReactionCounts = async (req, res, next) => {
  try {
    const post = req.post;
    const postId = post.feedId;

    const [commentCount, reactionCount, detailedReactions, userReactions] = await Promise.all([
      commentsMongo.instance.getCommentCountByPostId([postId]),
      reactionsMongo.instance.getReactionCountByPostId([postId]),
      reactionsMongo.instance.getDetailedReactionsByPostId([postId]),
      reactionsMongo.instance.getUserReactionsOnPosts(req.userId, [postId])
    ]);

    const userReaction = userReactions.length > 0 ? userReactions[0] : null;
    const reactionDetail = detailedReactions || { total: 0, types: {} };

    req.post = {
      ...post,
      commentCount: commentCount || 0,
      reactionCount: reactionCount || 0,
      reactionDetails: reactionDetail,
      reaction: {
        hasReacted: !!userReaction,
        reactionType: userReaction ? userReaction.reaction_type : null,
      }
    };

    next();
  } catch (err) {
    console.error('Error fetching comment/reaction counts:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

getPostDetails.buildResponse = (req, res) => {
  const { post } = req;
  res.status(200).json({ message: 'Post fetched successfully', post });
};

module.exports = getPostDetails;

