const {chatRooms : chatRoomsMongo, messageInteractions : messageInteractionsMongo, chatMessages : chatMessagesMongo} = require("../../db/mongo");

const userCache = {}

module.exports = (io, socket) => {
    // console.log(`Client connected: ${socket.user}`);

    const sendUnseenChatsCount = async () => {
        try {
            // Fetch unseen chats count for the user
            let chatRooms = await chatRoomsMongo.instance.getAllChatRooms(socket.user);

            const unseenChatsCount = await Promise.all(chatRooms.map(async (chatRoom) => {
                const messages = await chatMessagesMongo.instance.getLast10Messages(chatRoom.chatRoomId);
                      const unseenCount = await messageInteractionsMongo.instance.getUnseenCountForMessages(messages, socket.user);
                return unseenCount > 0 ? 1 : 0; // Count the chat room if it has unseen messages
            }));
            // Calculate the total unseen chats count
            const totalUnseenChats = unseenChatsCount.reduce((sum, count) => sum + count, 0);

            // Send the unseen chats count to the user
            socket.emit("unseenChats", { count: totalUnseenChats });
        } catch (error) {
            console.error("Error fetching unseen chats count:", error);
        }
    };

    socket.on("ping", sendUnseenChatsCount);

    // Handle client disconnection
    socket.on("disconnect", () => {
        // console.log(`Client disconnected: ${socket.user}`);
    });
};
