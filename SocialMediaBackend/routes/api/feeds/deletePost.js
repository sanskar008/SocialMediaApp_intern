const { feeds: feedsMongo } = require('../../../db/mongo');
const { FIELDS: FEEDS_FIELDS } = require('../../../db/mongo/feeds');

const deletePost = {};

/**
 * Middleware to validate the delete request.
 * Checks if the post exists and if the authenticated user is the author.
 */
deletePost.validateRequest = async (req, res, next) => {
    const { userId } = req; // Assuming userId is set by auth middleware
    const { post_id } = req.body; // post_id should be provided in the body
  
    if (!post_id) {
      return res.status(400).json({ message: 'post_id is required' });
    }
  
    try {

      const[id , date] = post_id.split(":");
      const feedsInstance = await feedsMongo.forDate(date);
      const post = await feedsInstance.getPostById(post_id);

      if (!post) {
        return res.status(404).json({ message: 'Post not found' });
      }
  
      if (post[FEEDS_FIELDS.AUTHOR] !== userId) {
        return res.status(403).json({ message: 'You are not the author of this post' });
      }
  
      // Store post_id and optionally post for later middlewares
      req.post_id = post_id;
      req.post = post;
      next();
    } catch (err) {
      console.error('Error fetching post for deletion:', err.message);
      return res.status(500).json({ message: 'Internal Server Error' });
    }
  };

/**
 * Middleware to delete the post from MongoDB.
 */
deletePost.deleteFromMongo = async (req, res, next) => {
  // Use req.post_id set in the previous middleware
  const post_id = req.post_id;
  try {

    const feedsInstance = await feedsMongo.forId(post_id);
    const deleted = await feedsInstance.deletePostById(post_id);

    if (!deleted) {
      return res.status(400).json({ message: 'Failed to delete post' });
    }
    next();
  } catch (err) {
    console.error('Error deleting post:', err.message);
    return res.status(500).json({ message: 'Internal Server Error' });
  }
};

/**
 * Middleware to build and send the response.
 */
deletePost.buildResponse = (req, res) => {
  res.status(200).json({ message: 'Post deleted successfully' });
};

module.exports = deletePost;
