const { feeds: feedsMongo } = require('../../../db/mongo');
const { FIELDS_VALUES : FEEDS_FIELDS_VALUES , FIELDS: FEEDS_FIELDS } = require('../../../db/mongo/feeds');

const editPost = {};

// Define editable fields in the `EDIT_FIELDS` object
const EDIT_FIELDS = { // if yahan se remove krenge toh niche se "ifs" bhi remove krdena
  CONTENT: 'content',
  PRIVACY: 'privacy',
  WHO_CAN_COMMENT: 'whoCanComment',
  TAGGED_USERS: 'taggedUsers',
  MENTIONED_USERS: 'mentionedUsers',
  HIDE_FROM: 'hideFrom',
  DATA: 'data',
  STATUS: 'status', // Optionally, you can allow editing status if needed
};

// Step 1: Validate the request body
editPost.validateRequestBody = (req, res, next) => {
    const { content, privacy, whoCanComment, taggedUsers, mentionedUsers, hideFrom } = req.body;

    // Check if any of the fields are invalid or missing
    const invalidFields = [];
    if (content && typeof content !== 'string') invalidFields.push('content');
    if (privacy && !Object.values(FEEDS_FIELDS_VALUES[FEEDS_FIELDS.PRIVACY]).includes(privacy)) invalidFields.push('privacy');
    if (whoCanComment && !Object.values(FEEDS_FIELDS_VALUES[FEEDS_FIELDS.WHO_CAN_COMMENT]).includes(whoCanComment)) invalidFields.push('whoCanComment');
    if (taggedUsers && !Array.isArray(taggedUsers)) invalidFields.push('taggedUsers');
    if (mentionedUsers && typeof mentionedUsers !== 'object') invalidFields.push('mentionedUsers');
    if (hideFrom && !Array.isArray(hideFrom)) invalidFields.push('hideFrom');
    
    if (invalidFields.length > 0) {
        return res.status(400).json({ message: `Invalid fields: ${invalidFields.join(', ')}` });
    }

    req.body.updatedFields = { content, privacy, whoCanComment, taggedUsers, mentionedUsers, hideFrom };  // Attach valid fields to the request body
    next();
};

// Step 2: Verify post belongs to the user
editPost.verifyPostBelongsToUser = async (req, res, next) => {
    const { userId } = req; // Assuming userId is available from the request (auth middleware)
    const { post_id } = req.body; // Mongo feed_id of the post to be edited

    try {
        // Fetch the post from MongoDB using the provided post_id
        const feedsInstance = await feedsMongo.forId(post_id)
        const post = await feedsInstance.getPostById(post_id);
        req._instance = feedsInstance

        if (!post) {
            return res.status(404).json({ message: 'Post not found' });
        }

        // Check if the authenticated user is the author of the post
        if (post[FEEDS_FIELDS.AUTHOR] !== userId) {
            return res.status(403).json({ message: 'You are not the author of this post' });
        }
        // console.log(post)
        next(); // Proceed to the next middleware (update the post)
    } catch (err) {
        console.error('Error fetching post for editing:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

// Step 3: Update the post in MongoDB

editPost.updatePost = async (req, res, next) => {
    const { post_id } = req.body;
    const { updatedFields } = req.body; // Get the updated fields from the request

    try {

        const updateObj = {};
        
        // Prepare the update object based on the fields provided
        if (updatedFields.content !== undefined) updateObj[FEEDS_FIELDS.DATA + '.content'] = updatedFields.content;
        if (updatedFields.privacy !== undefined) updateObj[FEEDS_FIELDS.PRIVACY] = updatedFields.privacy;
        if (updatedFields.whoCanComment !== undefined) updateObj[FEEDS_FIELDS.WHO_CAN_COMMENT] = updatedFields.whoCanComment;
        if (updatedFields.taggedUsers !== undefined) updateObj[FEEDS_FIELDS.TAGGED_USERS] = updatedFields.taggedUsers;
        if (updatedFields.mentionedUsers !== undefined) updateObj[FEEDS_FIELDS.MENTIONED_USERS] = updatedFields.mentionedUsers;
        if (updatedFields.hideFrom !== undefined) updateObj[FEEDS_FIELDS.HIDE_FROM] = updatedFields.hideFrom;

        // If no fields are provided for updating
        if (Object.keys(updateObj).length === 0) {
            return res.status(400).json({ message: 'No fields provided to update' });
        }

        // Update the post in MongoDB
        const feedInstance= req._instance
        const updatedPost = await feedInstance.updatePostById(post_id, updateObj);

        if (!updatedPost) {
            return res.status(400).json({ message: 'Failed to update post' });
        }

        req.updatedPost = updatedPost; // Attach the updated post to the request object
        next(); // Proceed to send the response
    } catch (err) {
        console.error('Error updating post:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

// Step 4: Build and send the response
editPost.buildResponse = (req, res) => {
    const { updatedPost } = req;
    res.status(200).json({ message: 'Post updated successfully', post: updatedPost });
};

module.exports = editPost;
