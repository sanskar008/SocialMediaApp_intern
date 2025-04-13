const { users: userRedis } = require("../../db/redis");
const { calls : callsMongo } = require("../../db/mongo");
const { callNotif } = require("../../routes/messages");
// Using Map instead of plain object for better performance
const userCache = new Map();
const callParticipants = new Map();

module.exports = (io, socket) => {
  // console.log(`Client connected: ${socket.user}`);

  // Helper function to fetch user details (cached for efficiency)
  const getUserDetails = async (socketId) => {
    if (!userCache.has(socketId)) {
      const user = await userRedis.getUserDetails(socketId);
      userCache.set(socketId, { user: JSON.parse(user), expiry: Date.now() + 600000 });
    }
    return userCache.get(socketId).user;
  };

  // ✅ Open Call (Host/Initiator joins the call room)
  socket.on("openCall", async (userId) => {
    if (!userId) {
      socket.emit("error", { message: "User ID required" });
      return;
    }

    await getUserDetails(socket.user);
    socket.join(userId);
  });

  // ✅ Join an existing call
  socket.on("joinCall", async ({ callId, userId }) => {
    if (!callId || !userId) {
      socket.emit("error", { message: "Call ID and User ID are required" });
      return;
    }

    const userInfo = await getUserDetails(socket.user);
    socket.join(callId);

    if (!callParticipants.has(callId)) {
      callParticipants.set(callId, []);
    }

    callParticipants.get(callId).push({ userId, userInfo });

    io.to(callId).emit("userJoined", {
      userId,
      userInfo,
      participants: callParticipants.get(callId),
    });
  });

  socket.on("add", async ({ callId, userId }) => {
    if (!callId || !userId) {
      socket.emit("error", { message: "Call ID and User ID are required to add participant" });
      return;
    }


    io.to(callId).emit("userAdded", {
      userId,
      userInfo,
      participants: callParticipants.get(callId),
    });

    // callsMongo.instance.addToCall({ userId, callId });
  });

  // ✅ Call Initialization (User calling another user)
  socket.on("callInit", async (data) => {
    if (data && typeof data === "string") {
            data = JSON.parse(data);
          }
      
    try {
      // Destructure the properties from the incoming data object
      const { callId, userId, otherIds, type } = data;
  
      // Validate the input data
      if (!callId || !userId || !otherIds || !Array.isArray(otherIds) || !type) {
        socket.emit("error", { message: "Invalid call data" });
        return;
      }
  
      // Fetch sender's information
      const senderInfo = await getUserDetails(socket.user);
  
      // Send initial notification (optional: batch for optimization)
      callNotif.send({ userId, callId, type });
  
      // Send call notifications to all recipients
      for (const otherId of otherIds) {
        io.to(otherId).emit("pickUp", {
          from: userId,
          senderInfo,
          callId,
          type,
        });
      }
  
      // Add initiator to participants if not already added
      if (!callParticipants.has(callId)) {
        callParticipants.set(callId, []);
      }
  
      const participants = callParticipants.get(callId);
  
      // Prevent duplicates
      if (!participants.find((p) => p.userId === userId)) {
        participants.push({ userId, userInfo: senderInfo });
        callParticipants.set(callId, participants);
      }
    } catch (error) {
      console.error("Error processing call initialization:", error);
      socket.emit("error", { message: "An error occurred while processing the call data." });
    }
  });
  
  
  // ✅ End Call
  socket.on("endCall", ({ callId, userId }) => {
    if (!callId || !userId) {
      socket.emit("error", { message: "Call ID and User ID are required" });
      return;
    }
  
    // Fetch participants for this call
    let participants = callParticipants.get(callId) || [];
  
    if (participants.length === 2) {
      // 🚀 If only 2 users, end call for **everyone**
      io.to(callId).emit("callEnded", { message: "Call Ended for all users" });
  
      // Clean up call data
      callParticipants.delete(callId);
    } else {
      // 🚀 If more than 2 users, remove only the user who ended the call
      participants = participants.filter((p) => p.userId !== userId);
      callParticipants.set(callId, participants);
  
      // Notify the specific user that they left the call
      io.to(userId).emit("callEnded", { message: "You have left the call" });
  
      // Notify others that this user has left
      io.to(callId).emit("userLeft", { userId });
    }
  
    // Leave socket room
    socket.leave(callId);
  });
  

  // ✅ Handle Client Disconnection (Cleanup Data)
  socket.on("disconnect", () => {
    // console.log(`Client disconnected: ${socket.user}`);

    // Remove user from all call rooms & update participants list
    for (const [callId, participants] of callParticipants.entries()) {
      const updatedParticipants = participants.filter((p) => p.userId !== socket.user);
      if (updatedParticipants.length === 0) {
        callParticipants.delete(callId);
      } else {
        callParticipants.set(callId, updatedParticipants);
      }
    }

    userCache.delete(socket.user);
  });
};
