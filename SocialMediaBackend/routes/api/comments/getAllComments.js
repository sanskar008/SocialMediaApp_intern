const { comments: commentsMongo, users: usersMongo } = require('../../../db/mongo');
const { FIELDS: COMMENT_FIELDS } = require('../../../db/mongo/comments');
const moment = require('moment');

const getAllComments = {};

// Validate request body
getAllComments.validateBody = (req, res, next) => {
  const { feedId } = req.body;
  console.log(req.body);

  if (!feedId) {
    return res.status(400).json({ success: false, message: 'Feed ID is required.' });
  }

  req.feedId = feedId;
  next();
};

getAllComments.fetchComments = async (req, res, next) => {
  const { feedId } = req;

  try {
    const comments = await commentsMongo.instance.getCommentsByPostId([feedId]);

    if (!comments || !comments.length) {
      return res.status(200).json({ success: true, message: 'No comments found.', comments: [] });
    }

    const flatComments = comments[0]?.comments || [];
    flatComments.sort((a, b) => new Date(a[COMMENT_FIELDS.CREATED_AT]) - new Date(b[COMMENT_FIELDS.CREATED_AT]));

    req.comments = flatComments;
    next();
  } catch (err) {
    console.error('Error fetching comments:', err.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

/**
 * Prepare the block filter by extracting user IDs from the comments.
 * We'll pass these IDs to the block service so it can filter out blocked relationships.
 */
getAllComments.prepareBlockFilter = (req, res, next) => {
  
  const userIds = req.comments.map(comment => comment.user_id);
  req._toBeFiltered = userIds;
  next();
  
};

/**
 * After the block service filters user IDs, remove comments from blocked users.
 */
getAllComments.filterOutBlockedComments = (req, res, next) => {
  const allowedUserIds = req.filteredAfterBlockCheckUserIds || [];

  req.comments = req.comments.filter(comment =>
    allowedUserIds.includes(comment.user_id)
  );
  
  next();
};

getAllComments.addUserDetails = async (req, res, next) => {
  const { comments } = req;
  const userIds = [...new Set(comments.map((comment) => comment[COMMENT_FIELDS.USER_ID]))];

  try {
    const userDetails = await usersMongo.instance.getUserShowingDetails(userIds);

    const commentsWithUserDetails = comments.map((comment) => {
      const userDetail = userDetails.find((user) => String(user.userId) === String(comment[COMMENT_FIELDS.USER_ID])) || {};
      return {
        commentId: comment[COMMENT_FIELDS.ID].toString(),
        postId: comment[COMMENT_FIELDS.POST_ID],
        parentComment: comment[COMMENT_FIELDS.PARENT_COMMENT] || null,
        comment: comment[COMMENT_FIELDS.COMMENT],
        createdAt: comment[COMMENT_FIELDS.CREATED_AT],
        agoTime: moment(comment[COMMENT_FIELDS.CREATED_AT]).fromNow(),
        user: {
          userId: userDetail.userId || null,
          name: userDetail.name || null,
          profilePic: userDetail.profilePic || null,
        },
      };
    });

    req.comments = commentsWithUserDetails;
    next();
  } catch (err) {
    console.error('Error adding user details:', err.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

getAllComments.buildResponse = (req, res) => {
  const { comments } = req;
  res.status(200).json({ success: true, message: 'Comments fetched successfully', comments });
};

module.exports = getAllComments;
