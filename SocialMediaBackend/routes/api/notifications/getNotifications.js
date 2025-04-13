const { notifications: notificationsMongo } = require("../../../db/mongo");

const getNotifications = {};

getNotifications.validateBody = (req, res, next) => {
  const { page = 1, limit = 20 } = req.query;
  
  // Validate pagination parameters
  const parsedPage = parseInt(page);
  const parsedLimit = parseInt(limit);
  
  if (isNaN(parsedPage) || parsedPage < 1 || isNaN(parsedLimit) || parsedLimit < 1 || parsedLimit > 100) {
    return res.status(400).json({
      success: false,
      message: "Invalid pagination parameters. Page must be >= 1 and limit must be between 1 and 100"
    });
  }
  
  req.pagination = {
    page: parsedPage,
    limit: parsedLimit
  };
  
  next();
};

getNotifications.fetch = async (req, res, next) => {
  try {
    const receiverId = req.userId;
    const { page, limit } = req.pagination;

    const [unseenResult, seenResult] = await Promise.all([
      notificationsMongo.instance.getUnseen(receiverId, page, limit),
      notificationsMongo.instance.getSeen(receiverId, page, limit)
    ]);

    // Combine results while maintaining pagination info
    req.notifications = {
      unseen: unseenResult.notifications,
      seen: seenResult.notifications,
      unseenCount: unseenResult.totalCount,
      totalCount: unseenResult.totalCount + seenResult.totalCount,
      currentPage: page,
      totalPages: Math.max(unseenResult.totalPages, seenResult.totalPages),
      hasMore: unseenResult.hasMore || seenResult.hasMore
    };

    next();
  } catch (err) {
    console.error("❌ Error fetching notifications:", err.message);
    return res.status(500).json({ 
      success: false, 
      message: "Failed to fetch notifications" 
    });
  }
};

getNotifications.buildResponse = (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Notifications fetched successfully",
    data: req.notifications
  });
};

getNotifications.getDotIndicator = async(req, res) => {
  try {
    const unseen = await notificationsMongo.instance.getUnseen(req.userId, 1, 1);
    return res.status(200).json({
      success: true,
      hasUnseen: unseen.totalCount > 0
    });
  } catch (err) {
    console.error("Error checking unseen notifications:", err);
    return res.status(500).json({
      success: false,
      message: "Failed to check unseen notifications"
    });
  }
};

module.exports = getNotifications;

