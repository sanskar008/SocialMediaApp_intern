const express = require("express");
const router = express.Router();
const auth = require("../auth");
const startMssg = require("./startMssg");
const editGroup = require("./editGroup");
const createGroup = require("./createGroup");
const getAllMessages = require("./getAllMessages");
const addParticipant = require("./addParticipants");
const mediaUpload = require('../../../media/upload');
const getAllChatRooms = require("./getAllChatRooms");
const removeParticipant = require("./removeParticipant");
const blockService = require("../blockService");
const getChatRoomDetails = require("./getChatRoomDetails");
const leaveChatRoom = require("./leaveChatRoom");

router.post(
  "/start-message",
  auth.validateUser,
  startMssg.validateRequest,
  startMssg.checkExistingChatRoom,
  startMssg.createChatRoom
);

router.post(
  "/create-group",
  auth.validateUser,
  createGroup.validateRequest,
  mediaUpload.uploader,
  createGroup.createChatGroup
);

router.put(
  "/edit-group",
  auth.validateUser,                
  editGroup.validateRequestBody,    
  editGroup.checkAdminPrivileges,   
  mediaUpload.uploader,             
  editGroup.updateGroupProfile      
);

router.put(
  "/add-participants",
  auth.validateUser,                  
  addParticipant.validateRequestBody, 
  addParticipant.checkAdminPrivileges, 
  addParticipant.addParticipantsToGroup 
);

router.post(
  "/remove-participant",
  auth.validateUser,
  removeParticipant.validateRequestBody, 
  removeParticipant.checkAdminPrivileges, 
  removeParticipant.removeParticipantFromGroup 
);

router.get(
  "/get-all-chat-rooms",
  auth.validateUser, 
  getAllChatRooms.fetchChatRooms,
  getAllChatRooms.fetchUnseenCounts,
  getAllChatRooms.prepareDMBlockFilter,
  blockService.filterBlockIdsMiddleware,
  getAllChatRooms.applyDMBlockFilter,
  getAllChatRooms.buildResponse
);

router.post(
  "/get-all-messages",
  auth.validateUser, 
  getAllMessages.validateRequest,
  getAllMessages.fetchMessages
);

router.get(
  "/get-chatroom-details",
  auth.validateUser,
  getChatRoomDetails.validateRequest,
  getChatRoomDetails.fetchChatRoom,     
  getChatRoomDetails.parseParticipants,      
  getChatRoomDetails.prepareDMBlockFilter,
  blockService.filterBlockIdsMiddleware,
  getChatRoomDetails.applyDMBlockFilter,
  getChatRoomDetails.filterActiveParticipants,
  getChatRoomDetails.buildResponse
);


router.post(
  "/leave-chatroom",
  auth.validateUser,
  leaveChatRoom.validateRequest,
  leaveChatRoom.verifyAdminLeave,
  leaveChatRoom.leaveRoom
);

module.exports = router;