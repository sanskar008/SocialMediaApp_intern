const { notifications: notificationsMongo } = require("../../../db/mongo");

const markAsSeen = {};

markAsSeen.validateBody = (req, res, next) => {
  const { notificationId, markAll } = req.body;

  if (!markAll && !notificationId) {
    return res.status(400).json({ success: false, message: "Either notificationId or markAll must be provided" });
  }

  next();
};

markAsSeen.mark = async (req, res, next) => {
  try {
    const receiverId = req.userId;
    const { notificationId, markAll } = req.body;

    if (markAll) {
      await notificationsMongo.instance.markAllAsSeen(receiverId);
    } else {
      const notification = await notificationsMongo.instance.getNotificationById(notificationId);

      if (!notification || notification.receiverId !== receiverId) {
        return res.status(401).json({ success: false, message: "Unauthorized access" });
      }

      await notificationsMongo.instance.markAsSeen(notificationId);
    }

    next();
  } catch (err) {
    console.error("❌ Error marking notifications as seen:", err.message);
    return res.status(500).json({ success: false, message: "Failed to mark notifications as seen" });
  }
};

markAsSeen.buildResponse = (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Notification(s) marked as seen",
  });
};

module.exports = markAsSeen;
