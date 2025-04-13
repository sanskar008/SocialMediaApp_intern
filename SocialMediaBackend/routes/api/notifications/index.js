const express = require("express");
const router = express.Router();

const auth = require("../auth");
const markAsSeen = require("./markAsSeen");
const getCallLogs = require("./getCallLogs");
const getNotifications = require("./getNotifications");
const deleteNotifications = require("./deleteNotifications");

// Fetch unseen notifications
router.get(
  "/get-notifications",
  auth.validateUser,
  getNotifications.validateBody,
  getNotifications.fetch,
  getNotifications.buildResponse
);

// Mark notifications as seen
router.post(
  "/mark-as-seen",
  auth.validateUser,
  markAsSeen.validateBody,
  markAsSeen.mark,
  markAsSeen.buildResponse
);

router.get('/notificationDot',
  auth.validateUser,
  getNotifications.getDotIndicator

)

router.get(
  "/get-call-logs",
  auth.validateUser,
  getCallLogs.validateBody,
  getCallLogs.fetch,
  getCallLogs.buildResponse
)

router.delete(
  "/delete-notification",
  auth.validateUser,
  deleteNotifications.validateBody,
  deleteNotifications.processDeletion,
  deleteNotifications.buildResponse
);

module.exports = router;
