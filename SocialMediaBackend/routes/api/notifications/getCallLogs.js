const { notifications: notificationsMongo, FIELDS } = require("../../../db/mongo");

const getCallLogs = {};

getCallLogs.validateBody = (req, res, next) => {
  next();
};

getCallLogs.fetch = async (req, res, next) => {
  try {
    const receiverId = req.userId;
    const { notifications } = await notificationsMongo.instance.getNotifications(receiverId);
    let callLogs = notifications.filter(notification => notification.type === "call");

    callLogs = callLogs.map(notification => {
      const callDetails = notification.details?.callDetails || {};
      const timeDetails = {};
      const participant = Array.isArray(callDetails.participants)
        ? callDetails.participants.find(p => p.userId === receiverId)
        : null;
      if (participant) {
        if (participant.status === "ended") {
          timeDetails.callTime = participant.updatedAt || participant.joinedAt;
        } else if (participant.status === "missed") {
          timeDetails.missedAt = callDetails.updatedAt;
        } else if (participant.status === "joined") {
          timeDetails.joinedAt = participant.joinedAt;
        }
      }
      return {
        ...notification,
        timeDetails
      };
    });

    req.callLogs = callLogs;
    next();
  } catch (err) {
    console.error("❌ Error fetching call logs:", err.message);
    return res.status(500).json({ success: false, message: "Failed to fetch call logs" });
  }
};

getCallLogs.buildResponse = (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Call logs fetched successfully",
    callLogs: req.callLogs,
  });
};

module.exports = getCallLogs;
