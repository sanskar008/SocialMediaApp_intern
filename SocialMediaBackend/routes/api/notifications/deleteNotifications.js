const { notifications: notificationsMongo } = require("../../../db/mongo");

const deleteNotifications = {};

deleteNotifications.validateBody = (req, res, next) => {
  const { clearAll, notificationId } = req.query;

  if (clearAll !== "1" && !notificationId) {

    return res.status(400).json({
      message: "Either clearAll: '1' or a valid notificationId must be provided"
    });

  }
  next();
};

deleteNotifications.processDeletion = async (req, res, next) => {
  const { clearAll, notificationId } = req.query;

  try {
    
    if (clearAll === "1") {
      req.deletedCount = await notificationsMongo.instance.clearAllNotifications(req.userId);
    } else {
      const success = await notificationsMongo.instance.deleteNotificationById(notificationId);
      req.deletedCount = success ? 1 : 0;
    }

    next();
  } catch (error) {
    console.error("Error deleting notifications:", error.message);
    return res.status(500).json({ message: "Failed to delete notifications" });
  }
};

deleteNotifications.buildResponse = (req, res) => {

  res.status(200).json({
    success: true,
    message: "Notifications deleted successfully",
    deletedCount: req.deletedCount
  });

};

module.exports = deleteNotifications;
