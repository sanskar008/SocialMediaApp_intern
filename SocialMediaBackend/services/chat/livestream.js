const { users: userRedis } = require("../../db/redis");

const userCache = {};
const streamCache = {}; // streamId => user (host)
const viewerCountCache = {}; // streamId => count
const socketStreamMap = {}; // socket.id => streamId

module.exports = (io, socket) => {
  socket.on("openStream", async (streamId) => {
    streamCache[streamId] = socket.user;
    viewerCountCache[streamId] = 1; // The host is the first viewer
    socketStreamMap[socket.id] = streamId;

    if (!userCache[socket.user]) {
      const user = await userRedis.getUserDetails(socket.user);
      userCache[socket.user] = { user, expiry: Date.now() + 600000 };
    }

    socket.join(streamId);
    io.to(streamId).emit("viewerCount", viewerCountCache[streamId]);
  });

  socket.on("joinStream", async (streamId) => {
    if (!userCache[socket.user]) {
      const user = await userRedis.getUserDetails(socket.user);
      userCache[socket.user] = { user, expiry: Date.now() + 600000 };
    }

    socket.join(streamId);
    socketStreamMap[socket.id] = streamId;

    // Update viewer count
    if (!viewerCountCache[streamId]) viewerCountCache[streamId] = 0;
    viewerCountCache[streamId]++;

    io.to(streamId).emit("joined", {
      user: JSON.parse(userCache[socket.user].user),
      streamId: streamId,
    });

    io.to(streamId).emit("viewerCount", viewerCountCache[streamId]);
  });

  socket.on("leaveStream", async () => {
    const streamId = socketStreamMap[socket.id];
    if (!streamId) return;
  
    // If the user is the owner of the stream
    if (streamCache[streamId] === socket.user) {
      // End the stream for everyone
      delete streamCache[streamId];
      delete viewerCountCache[streamId];
  
      io.to(streamId).emit("ended", {
        message: "Host left. Stream ended.",
      });
  
      // Leave all sockets from the room
      const sockets = await io.in(streamId).fetchSockets();
      sockets.forEach((s) => {
        s.leave(streamId);
        delete socketStreamMap[s.id];
      });
  
    } else {
      // Just a normal viewer
      socket.leave(streamId);
  
      if (viewerCountCache[streamId]) {
        viewerCountCache[streamId]--;
        if (viewerCountCache[streamId] < 0) viewerCountCache[streamId] = 0;
      }
  
      io.to(streamId).emit("viewerCount", viewerCountCache[streamId]);
      delete socketStreamMap[socket.id];
    }
  });
  

  socket.on("send", async (data) => {
    const { streamId, message } = data;

    if (!streamId || !message) {
      socket.emit("error", { message: "Invalid data" });
      return;
    }

    if (!userCache[socket.user]) {
      const user = await userRedis.getUserDetails(socket.user);
      userCache[socket.user] = { user, expiry: Date.now() + 600000 };
    }

    const senderInfo = userCache[socket.user];
    io.to(streamId).emit("receive", {
      senderInfo: JSON.parse(senderInfo.user),
      streamId,
      message,
    });
  });

  socket.on("endStream", async (data) => {
    const { streamId } = data;

    if (!streamId) {
      socket.emit("error", { message: "Stream Id is Needed" });
      return;
    }

    if (streamCache[streamId] !== socket.user) {
      socket.emit("error", { message: "You are not allowed to end this stream" });
      return;
    }

    delete streamCache[streamId];
    delete viewerCountCache[streamId];

    io.to(streamId).emit("ended", {
      message: "Stream Ended",
    });
  });

  // Handle disconnection
  socket.on("disconnect", () => {
    const streamId = socketStreamMap[socket.id];
    if (streamId) {
      socket.leave(streamId);

      if (viewerCountCache[streamId]) {
        viewerCountCache[streamId]--;
        if (viewerCountCache[streamId] < 0) viewerCountCache[streamId] = 0;
      }

      io.to(streamId).emit("viewerCount", viewerCountCache[streamId]);
      delete socketStreamMap[socket.id];
    }
  });
};
