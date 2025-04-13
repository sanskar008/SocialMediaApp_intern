// services/socketService.js
const { Server } = require("socket.io");
const authMiddleware = require('../chat/auth')
const chatRoute = require('../chat/message')
const callRoute = require('../chat/call');
const liveStream = require("../chat/livestream");
const notification = require("../notificationSocket/notification");

class SocketService {
  constructor(server) {
    // Initialize the Socket.IO server
    this.io = new Server(server, {
      cors: {
        origin: "*", // Adjust origin based on your client domain
        methods: ["GET", "POST"],
      },
    });

    this.io.use(async (socket, next) => {
      await authMiddleware.socket(socket, next);
    });

    // Handle socket connection
    this.io.on("connection", (socket) => {
      console.log(`Client connected: ${socket.user}`);
      

      chatRoute(this.io,socket)

      callRoute(this.io,socket)

      liveStream(this.io,socket)

      notification(this.io,socket)

      // Handle disconnection
      socket.on("disconnect", () => {
        console.log(`Client disconnected: ${socket.user}`);
      });
    });
  }

  // Emit a message to a specific client
  sendMessageToClient(clientId, event, message) {
    this.io.to(clientId).emit(event, message);
  }

  // Broadcast a message to all connected clients
  broadcastMessage(event, message) {
    this.io.emit(event, message);
  }
}

module.exports = SocketService;
