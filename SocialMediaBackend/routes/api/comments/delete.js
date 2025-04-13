const { comments: commentsMongo, feeds: FeedsMongo } = require('../../../db/mongo');
const { FIELDS: COMMENT_FIELDS } = require('../../../db/mongo/comments');

const deleteComment = {};

deleteComment.validateBody = (req, res, next) => {
  const { commentId, postId } = req.body;

  if (!commentId || !postId) {
    return res.status(400).json({ success: false, message: 'Missing JSON Body' });
  }
  next();
};

deleteComment.checkExistence = async (req, res, next) => {
  const { postId, commentId } = req.body;
  const userId = req.userId;

  try {
    const feedsInstance = await FeedsMongo.forId(postId);
    const post = await feedsInstance.getPostById(postId);
    if (!post) {
      return res.status(404).json({ success: false, message: 'Feed not Found' });
    }

    const commentPresent = await commentsMongo.instance.findComment(commentId);
    if (!commentPresent || commentPresent.length === 0) {
      return res.status(400).json({ success: false, message: 'No such comment found' });
    }

    const comment = commentPresent[0];

    if (String(comment[COMMENT_FIELDS.USER_ID]) !== String(userId) && String(post.author) !== String(userId)) {
      return res.status(403).json({ success: false, message: 'You do not have permission to delete this comment.' });
    }

    req.comment = comment;
    req.post = post;

    next();
  } catch (err) {
    console.error('Error validating comment existence:', err.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

deleteComment.deleteComment = async (req, res, next) => {
  const { commentId } = req.body;

  try {
    
    //this will delete both comment as well as its replies
    await commentsMongo.instance.deleteComment(commentId);

    next();
  } catch (err) {
    console.error('Error deleting comment : ', err.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

deleteComment.buildResponse = (req, res) => {
  return res.status(200).json({ success: true, message: 'Comment and its replies deleted successfully' });
};

module.exports = deleteComment;
