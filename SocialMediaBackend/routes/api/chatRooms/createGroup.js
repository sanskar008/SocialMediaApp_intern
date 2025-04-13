const { users: usersMongo, chatRooms: chatRoomsMongo } = require('../../../db/mongo');
const { parseParticipants } = require('./participantPaser');

const createGroup = {};

createGroup.validateRequest = (req, res, next) => {
  const userId = req.userId;
  if (req.body.participants && typeof req.body.participants == "string") {
    try {
      req.body.participants = JSON.parse(req.body.participants);
    } catch (e) {
      // If parsing fails, leave participants as is
    }
  }
  const { groupName, participants, image } = req.body;

  if (!userId) {
    return res.status(400).json({ error: "User ID (admin) is required." });
  }

  if (!groupName || typeof groupName !== "string") {
    return res.status(400).json({ error: "Group name is required and must be a string." });
  }

  if (!participants || !Array.isArray(participants) || participants.length < 2) {
    return res.status(400).json({ error: "Participants array is required and must include at least 2 users." });
  }

  if (!participants.includes(userId)) {
    participants.push(userId); 
  }
  req.body.entityType = "chatRoom"


  next();
};

createGroup.createChatGroup = async (req, res) => {
  const userId = req.userId; 
  const { groupName, participants } = req.body;
  const profileUrl = req && req._media && req._media[0] ? req._media[0].url : null;

  try {
    
    let chatRoom = await chatRoomsMongo.instance.createChatGroupRoom(participants , userId , groupName, profileUrl ); //userId is admin

    chatRoom = await parseParticipants(chatRoom);

    return res.status(201).json({ message: "Group chat created successfully.", chatRoom });
  } catch (err) {
    return res.status(500).json({ error: "Error creating group chat.", details: err.message });
  }
};

module.exports = createGroup;
