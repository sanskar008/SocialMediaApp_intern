const { users : usersMongo, stories : storiesMongo ,followers : followersMongo , liveStreams : liveStreamsMongo , storiesInteraction : storiesInteractionMongo } = require('../../../db/mongo')
const { FIELDS } = require('../../../db/mongo/followers');
const moment = require('moment');

const getStories = {};

getStories.validateRequest = (req, res, next) => {
  if (!req.body || !req.body.userId) {
    return res.status(400).json({
      message: "Missing required field: userId",
    });
  }
  req.body.followingUserIds = [req.body.userId];
  next();
};

getStories.followingCheck = async (req, res, next) => {
  next();
};


getStories.getAllFollowings = async(req, res, next) => {
    const userId = req.userId;
    const requests = await followersMongo.instance.getFollowings( userId);
    const followingUserIds = requests.map(request => ( request[FIELDS.SENT_TO] ));
    req.body.followingUserIds = followingUserIds;
    
    next();
};

getStories.addLiveStreams = async (req, res, next) => {
  const { followingUserIds } = req.body;

  try {
    const activeLiveStreams = await liveStreamsMongo.instance.getActiveLiveStreams(followingUserIds);

    // Create a map of active live streams for quick lookup
    const liveStreamsMap = activeLiveStreams.reduce((map, stream) => {
      map[stream.userId] = {
        isLive: true,
        channelName: stream.channelName,
        updatedAt: stream.updatedAt,
      };
      return map;
    }, {});

    // Ensure `userStoriesData` exists
    if (!req.body.userStoriesData) {
      req.body.userStoriesData = [];
    }

    // Merge live streams into userStoriesData
    req.body.userStoriesData = req.body.userStoriesData.map((user) => ({
      ...user,
      isLive: liveStreamsMap[user.userId]?.isLive || user.isLive || false, // Prioritize live stream status
      channelName: liveStreamsMap[user.userId]?.channelName || user.channelName || null,
      hasStory: !!user.latestStory || false, // Ensure hasStory remains true if the user has a story
    }));

    next();
  } catch (error) {
    console.error("Error adding live streams to stories:", error.message);
    return res.status(500).json({ message: "Failed to add live streams." });
  }
};


getStories.setUserIdsOrder = async (req, res, next) => {
  const { followingUserIds } = req.body;
  const userId = req.userId;

  try {
    const latestStories = await storiesMongo.instance.getUserLatestActiveStory(followingUserIds);
    const viewedStoriesDict = await storiesInteractionMongo.instance.getStoriesViewedByUser(userId);
    const activeLiveStreams = await liveStreamsMongo.instance.getActiveLiveStreams(followingUserIds);

    // Map live streams for quick lookup
    const liveStreamsMap = activeLiveStreams.reduce((map, stream) => {
      map[stream.userId] = {
        isLive: true,
        updatedAt: stream.updatedAt,
      };
      return map;
    }, {});

    // Build userStoriesData from latestStories
    const userStoriesData = latestStories.map(({ userId: followingId, data: latestStory }) => {
      const isSeen = viewedStoriesDict[latestStory._id.toString()] ? true : false;

      return {
        userId: followingId,
        latestStoryTime: latestStory.createdAt,
        priority: isSeen ? 2 : 1, // Priority: Unseen stories > Seen stories
        isLive: !!liveStreamsMap[followingId], // Set isLive based on liveStreamsMap
        hasStory: true,
      };
    });

    // Add live stream users without stories
    activeLiveStreams.forEach((stream) => {
      if (!userStoriesData.some((user) => user.userId === stream.userId)) {
        userStoriesData.push({
          userId: stream.userId,
          latestStoryTime: stream.updatedAt,
          priority: 3, // Lower priority than stories
          isLive: true,
          hasStory: false,
        });
      }
    });

    // Sort by priority and latest time
    userStoriesData.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority - b.priority;
      }
      return b.latestStoryTime - a.latestStoryTime;
    });

    req.body.userStoriesData = userStoriesData;
    req.viewedStoriesDict = viewedStoriesDict;

    next();
  } catch (err) {
    console.error("Error setting user order based on latest stories and live streams:", err.message);
    return res.status(500).json({ message: "Failed to set user order." });
  }
};

getStories.getStoriesFromFollowings = async (req, res, next) => {
  const { followingUserIds } = req.body; 
  const storiesData = {};

  try {
    const userStories = await storiesMongo.instance.getUserActiveStories(followingUserIds); // Fetch stories as {userId, storiesArray}

    userStories.forEach(({ userId, storiesArray }) => {
      if (storiesArray.length > 0) {
        const storiesWithTtl = storiesArray.map(story => {
          const ago_time = getTimeAgo(story.createdAt);
          return { ...story, ago_time };
        });

        storiesData[userId] = storiesWithTtl;
      }
    });

    req.body.storiesData = storiesData;
    next();
  } catch (err) {
    console.error('Error fetching stories from followers:', err.message);
    return res.status(500).json({ message: 'Failed to fetch stories from followers' });
  }
};


getStories.setUserData = async (req, res, next) => {
  const { userStoriesData } = req.body;

  try {
    const userIds = userStoriesData.map(user => user.userId);
    const userDetailsArray = await usersMongo.instance.getUserDetailsFromIds(userIds);

    const userDetailsMap = userDetailsArray.reduce((acc, user) => {
      const userIdString = user._id.toString();
      acc[userIdString] = {
        name: user.name,
        profilePic: user.profilePic
      };
      return acc;
    }, {});

    req.body.userStoriesData = userStoriesData.map(user => ({
      ...user,
      name: userDetailsMap[user.userId]?.name,
      profilePic: userDetailsMap[user.userId]?.profilePic
    }));

    next();
  } catch (err) {
    console.error("Error fetching user data for stories:", err.message);
    return res.status(500).json({ message: "Failed to fetch user data for stories" });
  }
};

getStories.setSeen = async (req, res, next) => {
  const { storiesData } = req.body;
  const viewedStoriesDict = req.viewedStoriesDict; 
  const userId = req.userId;

  try {
    for (const userIdKey in storiesData) {
      let foundUnseen = false;

      storiesData[userIdKey] = storiesData[userIdKey].map((story) => {
        if (foundUnseen) {
          return { ...story, seen: 0 };
        }

        const hasSeen = viewedStoriesDict && viewedStoriesDict[story._id.toString()];

        if (!hasSeen) {
          foundUnseen = true; 
          return { ...story, seen: 0 };
        }

        return { ...story, seen: 1 }; 
      });
    }

    next();
  } catch (err) {
    console.error('Error setting seen status for stories:', err.message);
    return res.status(500).json({ message: 'Failed to set seen status for stories' });
  }
};

getStories.prepareStoriesBlockFilter = (req, res, next) => {
  try {
    const userStoriesData = req.body.userStoriesData || [];
    const storyUserIds = userStoriesData.map(story => story.userId);
    req._toBeFiltered = storyUserIds;
    next();
  } catch (err) {
    console.error("Error in prepareStoriesBlockFilter:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};

getStories.applyStoriesBlockFilter = (req, res, next) => {
  try {
    const allowedUserIds = req.filteredAfterBlockCheckUserIds || [];
    req.body.userStoriesData = (req.body.userStoriesData || []).filter(story =>
      allowedUserIds.includes(story.userId)
    );
    next();
  } catch (err) {
    console.error("Error in applyStoriesBlockFilter:", err.message);
    return res.status(500).json({ message: "Internal Server Error" });
  }
};


getStories.buildResponse = (req, res) => {
  const { userStoriesData } = req.body;

  res.status(200).json({
    message: "Stories fetched successfully",
    stories: userStoriesData.map((user) => ({
      userId: user.userId,
      name: user.name,
      profilePic: user.profilePic,
      isLive: user.isLive,
      hasStory: user.hasStory,
      latestStoryTime: user.latestStoryTime,
      stories: user.hasStory ? req.body.storiesData[user.userId] || [] : [],
      channelName: user.isLive ? user.channelName : null,
    })),
  });
};


function getTimeAgo(createdAt) {
  const timeAgo = moment.unix(createdAt).fromNow();  
  return timeAgo;
}


// ##------------------------------------

getStories.getSelfStories = async (req, res , next) => {
  const userId = req.userId;

  try {
    const userStories = await storiesMongo.instance.getUserActiveStories([userId]);

    if (userStories.length === 0 || !userStories[0].storiesArray.length) {
      return res.status(200).json({
        message: 'No stories available',
        stories: [],
      });
    }

    req.body.storiesWithDetails = userStories[0].storiesArray.map((story) => ({
      ...story,
      ago_time: getTimeAgo(story.createdAt),
    }));


    next();
  } catch (err) {
    console.error('Error fetching self stories:', err.message);
    return res.status(500).json({
      message: 'Failed to fetch self stories',
      stories: [],
    });
  }
};

getStories.setHasViewed = async (req, res) => {
  try {
    const stories = req.body.storiesWithDetails;
    const storyIds = stories.map((story) => story._id.toString());

    const someoneHasViewedMap = await storiesInteractionMongo.instance.hasStoriesBeenViewed(storyIds);

    console.log(someoneHasViewedMap);

    const storiesWithViewedStatus = storyIds.map((storyId) => {
      const story = stories.find((s) => s._id.toString() === storyId);
      return {
        ...story,
        someoneHasViewed: someoneHasViewedMap[storyId] || false,
      };
    });

    res.status(200).json({
      message: 'Stories fetched successfully',
      stories: storiesWithViewedStatus,
    });
  } catch (err) {
    console.error('Error setting someoneHasViewed status for stories:', err.message);
    return res.status(500).json({
      message: 'Failed to set someoneHasViewed status for self stories',
      stories: [],
    });
  }
};




module.exports = getStories;
