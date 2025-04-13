const moment = require("moment");
const { messageHandler } = require("../../routes/messages");
const { socketData: socketDataRedis } = require("../../db/redis");
const { users: userRedis } = require("../../db/redis");
const bot = require("./bot");
const { chatMessages } = require("../../db/mongo");

const userCache = {}

module.exports = (io, socket) => {
  // console.log(`Client connected: ${socket.user}`);


  socket.on("join", async (entityId) => {
    const valid = await messageHandler.checkAuthorization(socket.user, entityId); // Remember socket.user was the user id
    if (!valid)
      socket.emit("error", {
        message: "Action Not allowed",
        reason: "You are not allowed to send Message to this Room",
      });
    else {
      if (!userCache[socket.user]) {
        const user = await userRedis.getUserDetails(socket.user);
        userCache[socket.user] = { user, expiry: Date.now() + 600000 };
      }

      socketDataRedis.addUserToRoom(socket.user, entityId);
      socket.join(entityId);
      console.log(`Client joined room: ${entityId} ${socket?.id}`);
      socket.emit("success", {
        message: `${socket.user} ,Welcome to the ChatRoom`,
      });
    }
  });

  socket.on("sendMessage", async (data) => {
    if (data && typeof data === "string") {
      data = JSON.parse(data);
    }
    console.log(data)
    const { senderId, content, entityId, media, entity, isBot, isSpeakerOn, voice, replyTo } = data;

    if (!senderId || (!content && !media) || !entityId) {
      socket.emit("error", { message: "Invalid data" });
      return;
    }

    const message = await messageHandler.createMessage(data, replyTo);

    if (isBot) {
      await bot.handleBotMessage(data, socket, io);
      return;
    }
    
    socket.emit("success", {
      message: "Message sent successfully",
      timestamp: moment().unix(),
    });

    if (!userCache[socket.user]) {
      const user = await userRedis.getUserDetails(socket.user);
      userCache[socket.user] = { user, expiry: Date.now() + 600000 };
    }
    const senderInfo = userCache[socket.user];
    messageHandler.sendNotificationsToOffline(entityId, content, senderId);

    io.to(entityId).emit("receiveMessage", {
      ...message,
      senderInfo: JSON.parse(senderInfo.user),
      timestamp: moment().unix(),
    });

    // Optional: Save message to database
    // (Assume a saveMessage function exists in your messageController)
    // saveMessage({ entityId, senderId, content });
  });

  socket.on("reactToMessage", async (data) => {
    const { messageId, reaction } = data;
    if (!messageId || !reaction) {
      socket.emit("error", { message: "Invalid reaction data" });
      return;
    }

    try {
      await chatMessages.addReaction(messageId, socket.user, reaction);
      io.to(data.entityId).emit("messageReaction", {
        messageId,
        reaction,
        userId: socket.user,
        timestamp: moment().unix()
      });
    } catch (error) {
      socket.emit("error", { message: "Failed to add reaction" });
    }
  });

  socket.on("removeReaction", async (data) => {
    const { messageId, entityId } = data;
    if (!messageId) {
      socket.emit("error", { message: "Invalid message ID" });
      return;
    }

    try {
      await chatMessages.removeReaction(messageId, socket.user);
      io.to(entityId).emit("reactionRemoved", {
        messageId,
        userId: socket.user
      });
    } catch (error) {
      socket.emit("error", { message: "Failed to remove reaction" });
    }
  });

  socket.on("markMessageAsSeen", async (data) => {
    const { messageId, entityId } = data;
    if (!messageId) {
      socket.emit("error", { message: "Invalid message ID" });
      return;
    }

    try {
      await chatMessages.markMessageAsSeen(messageId, socket.user);
      io.to(entityId).emit("messageSeen", {
        messageId,
        userId: socket.user,
        timestamp: moment().unix()
      });
    } catch (error) {
      socket.emit("error", { message: "Failed to mark message as seen" });
    }
  });

  socket.on("leave", async (entityId) => {
    socket.leave(entityId);
    socketDataRedis.removeUserFromRoom(socket.user, entityId);
    delete userCache[socket.user];
    // console.log(`Client left room: ${entityId} ${socket.user}`);
    socket.emit("success", {
      message: `${socket.user} has left the ChatRoom`,
    });
    io.to(entityId).emit("success",{
      message: `${socket.user} has left the ChatRoom`
    })
  });

  // Handle client disconnection
  socket.on("disconnect", () => {
    // console.log(`Client disconnected: ${socket.user}`);
  });
};
