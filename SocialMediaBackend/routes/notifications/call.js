const NotificationSaver = require("./notificationSaver");
const { users: usersMongo } = require("../../db/mongo");
const { instance: ChatRooms, FIELDS: ChatRoomFIELDS } = require("../../db/mongo/chatRooms");

const callNotification = {};

/**
 * Send a call notification.
 *
 * Frontend sends a payload with { callId, status, call, reqUserId }.
 *
 * - call: the complete call object from the calls collection (including from, to, participants, etc.)
 * - status: the updated call status ("missed", "ongoing", "ended")
 * - callId: the unique ID of the call record
 * - reqUserId: the current user's ID (i.e. the receiver of the notification)
 *
 * Notification building:
 * - The sender object will have:
 *    - id: set to the chatRoomId (from call.to)
 *    - name: if group room then group name, otherwise the call initiator’s name (from shown details)
 *    - profilePic: if group room then group's profile URL, otherwise call initiator’s profilePic
 * - The receiver is reqUserId.
 * - The entire call object is added to callDetails.
 */
callNotification.send = async ({ call, status, callId , receiverId }) => {
  try {
    // Get chatRoomId from the call's "to" field.
    const chatRoomId = call.to;
    const chatRoom = await ChatRooms.getChatRoomByChatRoomId(chatRoomId);

    let sender = {};
    if (chatRoom[ChatRoomFIELDS.ROOM_TYPE] === "group") {
      // For a group chat:
      sender.id = chatRoomId;
      sender.name = chatRoom[ChatRoomFIELDS.GROUP_NAME] || "Group Call";
      sender.profilePic = chatRoom[ChatRoomFIELDS.PROFILE_URL] || null;
    } else if (chatRoom[ChatRoomFIELDS.ROOM_TYPE] === "dm") {
      // For a DM, fetch the call initiator's shown details.
      const userDetails = await usersMongo.instance.getUserShowingDetails([call.from]);
      const callInitiator = userDetails[0] || {};
      sender.id = chatRoomId; // Sender id is still the chat room id.
      sender.name = callInitiator.name || "Unknown";
      sender.profilePic = callInitiator.profilePic || null;
    }

    // Build a notification text based on call status.
    let notificationText = "Call log";
    if (status === "missed") {
      notificationText = "Missed call";
    } else if (status === "ongoing") { // ispe notification save nahi hogi , ye case aane hi nhi derhe
      notificationText = "Call is ongoing";
    } else if (status === "ended") {
      notificationText = "Call ended";
    }
    // Save the notification including the entire call object.
    await NotificationSaver.saveNotification({
      type: "call",
      sender, // Contains chatRoomId, name and profilePic per the room type.
      receiverId, // Current user's ID.
      details: {
        entityType: "call",
        entityId: callId,
        notificationText,
        status,
        callDetails: call, // Entire call object.
        headerId: callId,
      },
    });
  } catch (err) {
    console.error("❌ Error processing call notification:", err.message);
  }
};

module.exports = callNotification;
