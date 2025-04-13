const { FIELDS, FIELDS_VALUES } = require('../../../db/mongo/stories');
const moment = require('moment');
const { stories : storiesMongo } = require('../../../db/mongo');

const uploadStory = {};

uploadStory.formDataWrapper = (req,res,next) => {
  const body = req.body;
  
  req.body = {
    "entityType": "story",  
    
    "contentType" : body.contentType,
    "privacy": Number(body.privacy),  
    "repliesEnabled": body.repliesEnabled ? Number(body.repliesEnabled) : 0,  // Default to 0 if not provided
    "taggedUsers": typeof body.taggedUsers === 'string' ? [body.taggedUsers] : body.taggedUsers,  // Parse tagged users if it's a string
    
    "privateTo": body.privateTo || [],  

    "hideFrom": body.hideFrom || [],  

    "createdAt": Date.now(),  

    "updatedAt": Date.now(),  

    "url": "https::www.example.com/stories",
  };
  
  req._files = req.files;  
  next();  
};

uploadStory.validateRequestBody = (req, res, next) => {

    const { privacy, contentType } = req.body; 

    req.body.createdAt = moment().unix(); 
    if (!Object.values(FIELDS_VALUES[FIELDS.PRIVACY]).includes(privacy)) {
        return res.status(400).json({ message: 'Invalid privacy value' });
    }

    if (!Object.values(FIELDS_VALUES[FIELDS.CONTENT_TYPE]).includes(contentType)) {
        return res.status(400).json({ message: 'Invalid contentType value' });
    }

    if (Array.isArray(req.body.taggedUsers)) {
        req.body.taggedUsers = req.body.taggedUsers.filter(el => typeof el === 'string'); // Filter invalid values
    } else {
        delete req.body.taggedUsers; 
    }

    req._files = req.files;

    next(); 
};

uploadStory.saveStoryToDB = async (req, res, next) => {
  try {
    const fileData = req?._media;
    req.body.url = fileData[0].url;

    const toAdd = {
      [FIELDS.AUTHOR]: req.userId,
      [FIELDS.PRIVACY]: req.body.privacy,
      [FIELDS.CONTENT_TYPE]: req.body.contentType,
      [FIELDS.TAGGED_USERS]: req.body.taggedUsers,
      [FIELDS.HIDE_FROM]: req.body.hideFrom,
      [FIELDS.CREATED_AT]: req.body.createdAt,
      [FIELDS.URL]: req.body.url,
      [FIELDS.STATUS] : FIELDS_VALUES[FIELDS.STATUS].LIVE,
    };

    req._dataAdded = toAdd;

    const mongoResult = await storiesMongo.instance.insertStory(toAdd);

    if (mongoResult) {
      next();
    } else {
      res.status(500).json({ message: 'Failed to save story to database' });
    }

  } catch (err) {
    console.error('Error saving story to DB:', err);
    res.status(500).json({ message: 'Internal Server Error: Failed to save story' });
  }
};

uploadStory.buildResponse = (req, res) => {

  const dataObj = req._dataAdded ;
  res.status(200).json(dataObj);

};

module.exports = uploadStory;