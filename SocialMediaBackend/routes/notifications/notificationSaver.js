const notificationsMongo = require("../../db/mongo/notifications");

const NotificationSaver = {};

/**
 * ✅ Save Notification
 */
NotificationSaver.saveNotification = async (notificationData) => {
  try {
    await notificationsMongo.instance.addNotification(notificationData);
  } catch (err) {
    console.error("❌ Error saving notification:", err.message);
  }
};

module.exports = NotificationSaver;
