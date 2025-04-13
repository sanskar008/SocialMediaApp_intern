const { feeds: feedsMongo } = require('../../../db/mongo')
const { FIELDS : FEEDS_FIELDS, FIELDS_VALUES : FEEDS_FIELDS_VALUES} = require('../../../db/mongo/feeds')
const moment = require('moment')
const createPost ={}
const axios = require('axios');
require('dotenv').config();

createPost.formDataWrapper = (req, res, next) => {
    const body = req.body;
    req.body = {
      "data": {
        "content": body.content, //content is basically the caption of the post 
        "media" : `https://example.com/pre-generated-url, with body content = ${body.content}`
      },
      "privacy": Number(body.privacy),
      "whoCanComment": body.whoCanComment ? Number(body.whoCanComment) : 0,
      "taggedUsers": typeof body.taggedUsers === 'string' ? [body.taggedUsers] : body.taggedUsers,
      "mentionedUsers": body.mentionedUsers
        ? typeof body.mentionedUsers === 'object'
          ? body.mentionedUsers
          : typeof body.mentionedUsers === 'string'
            ? JSON.parse(body.mentionedUsers)
            : {}
        : {},
      "privateTo": body.privateTo 
        ? (typeof body.privateTo === 'string' 
          ? body.privateTo.split(',').map(id => id.trim()) 
          : Array.isArray(body.privateTo) 
            ? body.privateTo 
            : [])
        : [],
      "hideFrom": body.hideFrom
        ? (typeof body.hideFrom === 'string'
          ? body.hideFrom.split(',').map(id => id.trim())
          : Array.isArray(body.hideFrom)
            ? body.hideFrom
            : [])
        : [],
      "entityType":"post",
      "tag": typeof body.tag === 'string' ? body.tag.split(',').map(el => el.trim().toLowerCase()) : body.tag,
    }
    req._files = req.files;
    next();
  }

createPost.validateBody= (req,res,next) => {
    let { privacy, data } = req.body; 

    req.body.createdAt = moment().unix(); // createdAt time stamp for the post 


    if (!Object.values(FEEDS_FIELDS_VALUES[FEEDS_FIELDS.PRIVACY]).includes(privacy)) return res.status(400).json({message: 'Invalid JSON body'})
    if (Object.keys(req.body).includes('whoCanComment') && !Object.values(FEEDS_FIELDS_VALUES[FEEDS_FIELDS.WHO_CAN_COMMENT]).includes(req.body.whoCanComment)) return res.status(400).json({message:'Invalid JSON body'})


    if (Array.isArray(req.body.taggedUsers)) {
      req.body.taggedUsers = req.body.taggedUsers.filter(el => (typeof el === 'string' && el !== userId));
    } else {
      delete req.body.taggedUsers;
    }
    next();
}

createPost.saveToMongo = async(req,res,next) => {
  const fileData = req._media
  req.body.data.media = fileData;
  const date =moment().format("YYYY-MM-DD");
  const toAdd = {
  [FEEDS_FIELDS.AUTHOR] : req.userId,
  [FEEDS_FIELDS.WHO_CAN_COMMENT]: req.body.whoCanComment,
  [FEEDS_FIELDS.PRIVACY] : req.body.privacy,
  [FEEDS_FIELDS.CONTENT_TYPE] : req.body.contentType,
  [FEEDS_FIELDS.TAGGED_USERS] : req.body.taggedUsers,
  [FEEDS_FIELDS.PRIVATE_TO] : req.body.privateTo,
  [FEEDS_FIELDS.HIDE_FROM] : req.body.hideFrom,
  [FEEDS_FIELDS.STATUS] : FEEDS_FIELDS_VALUES[FEEDS_FIELDS.STATUS].LIVE,
  [FEEDS_FIELDS.CREATED_AT] : req.body.createdAt,
  [FEEDS_FIELDS.DATA] : req.body.data,
  [FEEDS_FIELDS.FEED_ID] : date
  }

  const feedsInstance = await feedsMongo.forDate(date)
  req._dataAdded = toAdd

  const mongoResult = await feedsInstance.createPost(toAdd);
  mongoResult && mongoResult.original && (req._id = feedsInstance.getStringFromObjectId(mongoResult.original._id));
  if (!req._id) return res.status(400).json({success:false, message:'Internal Server Error'});
  next();
}

createPost.saveInEs = async(req,res,next) => {
  next();

}

createPost.buildResponse = (req,res,next) => {
  const dataObj = req._dataAdded ;

  res.status(200).json(dataObj);

  next();


}


createPost.sendMentionedNotifications = (req,res,next) => {
  next();

  //handle mentioned users notification
}

createPost.sendTaggedNotification = (req,res,next) => {
  next();

  //handle tagged users notification
}

createPost.rewriteWithBond = async(req, res) => {

  try {

    const { caption } = req.body;

    if (!caption || caption.trim().length === 0) {
      return res.status(400).json({ message: "Caption is required" });
    }

    const prompt = `Rewrite the following caption in a more engaging, creative, and catchy way for social media:\n\n"${caption}"`;

    // Call OpenAI API
    const response = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "system", content: prompt }
          ],
          max_tokens: 50,
        },
        {
          headers: {
            Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
            "Content-Type": "application/json",
          },
        }
      );

    const rewrittenCaption = response.data.choices[0].message.content.trim();

    res.json({ original: caption, rewritten: rewrittenCaption });

} catch (error) {
    console.error("Error re-writing with Bond.", error);
    res.status(500).json({ message: "Server error" });
}
}

module.exports = createPost