const axios = require('axios');
const { messageHandler } = require("../../routes/messages");
const moment = require("moment");
require('dotenv').config();
const AWS = require('aws-sdk');
const { users: userMongo } = require('../../db/mongo');
const fs = require('fs');
const path = require('path');
const { checkIfUserShowedInterest } = require('./findInterest');
const { Polly } = require('aws-sdk');

const bot = {};

AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_SECRET_KEY,
  region: process.env.AWS_REGION
});
// const polly = new AWS.Polly();


bot.getPollyAudio = async (text, voiceId) => {
  const polly = new Polly();
  const params = {
    OutputFormat: "mp3",
    Text: text,
    VoiceId: voiceId,
    Engine: "standard",
  };

  try {
    //const data = await polly.synthesizeSpeech(params).promise();

    if (voiceId == '') {
      return null;
    }

    const data = await polly.describeVoices({ LanguageCode: "en-US" }).promise();
    const selectedVoice = data.Voices.find(v => v.Id === voiceId);

    if (!selectedVoice) {
      console.log(`⚠ Voice ${voiceId} not found, defaulting to Joanna.`);
    } else {
      console.log(`🛠 Polly Voice Selected: ${selectedVoice.Id}`);
      console.log(`🎙️ Available Engines: ${selectedVoice.SupportedEngines}`);
    }
    // const data = await polly.describeVoices({ VoiceId: voiceId }).promise();
    // const selectedVoice = data.Voices[0];

    // console.log(`🛠 Polly Voice Selected: ${selectedVoice.Name}`);
    // console.log(`🎙️ Engine Used: ${selectedVoice.SupportedEngines}`);

    // const speechParams = {
    //   ...params,
    //   Engine: "standard", // ✅ Explicitly set Standard engine
    // };

    const speechData = await polly.synthesizeSpeech(params).promise();
    if (speechData.AudioStream) {
      // Convert binary audio data to base64
      return speechData.AudioStream.toString('base64');
    } else {
      return null;
    }
  } catch (error) {
    console.error("Polly Error:", error);
    return null;
  }
};

const loadSpamWords = () => {
  const spamFilePath = path.join(__dirname, '../../spam_words.json');
  try {
    const spamData = JSON.parse(fs.readFileSync(spamFilePath, 'utf-8'));
    if (Array.isArray(spamData.spamWords)) {
      spamWordsSet = new Set(spamData.spamWords.map(word => word.toLowerCase()));
      console.log(`✅ Loaded ${spamWordsSet.size} spam words from JSON`);
    } else {
      console.error("⚠ Invalid JSON format. Expected { words: [\"word1\", \"word2\"] }");
    }
  } catch (error) {
    console.error("⚠ Error loading spam words:", error);
  }
};

loadSpamWords();

const isSpamMessage = (message) => {
  const words = message.toLowerCase().split(/\s+/);
  return words.some(word => spamWordsSet.has(word));
};

bot.getBotResponse = async (userMessage, senderId, voice) => {
  try {

    if (isSpamMessage(userMessage)) {
      return "⚠ This message was flagged as spam and cannot be processed.";
    }

    const lowerCaseMessage = userMessage.toLowerCase();
    const result = await checkIfUserShowedInterest(lowerCaseMessage);
    const { interest, didUserAskForFriends } = result;

    // If interest is shown according to the AI check
    if (didUserAskForFriends) {
      console.log('chalra hai');
      console.log(`Detected Positive Interest: ${interest}`);
      let matchingUsers = await userMongo.instance.findUsersByInterest(senderId, interest);

      if (matchingUsers.length > 0) {
        return {
          message: `I see you're interested in ${interest}! Here are some users with similar interests:`,
          users: matchingUsers
        };
      } else {
        return `I see you're interested in ${interest}, but I couldn't find any matching users at the moment.`;
      }
    }

    let systemPrompt = `You are an AI chatbot named Michael, friendly and funny.`

    if(voice == 'female'){
    systemPrompt = `You are an AI chatbot named Vanessa, friendly and funny.`
    }

    const response = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage },
        ],
        max_completion_tokens: 100,
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    return response.data.choices[0].message.content;
  } catch (error) {
    console.error("⚠ OpenAI Error:", error.response ? error.response.data : error.message);
    return "Sorry, I couldn't process that.";
  }
}

bot.handleBotMessage = async (data, socket, io) => {
  const { content, entityId, entity, senderId , isSpeakerOn , voice } = data;
  try {

    const botResponse = await bot.getBotResponse(content, senderId, voice);
    console.log("bot responded",botResponse);
    let userProfiles = []
    let suggestedFriends = []
    if (Array.isArray(botResponse)) {
      userProfiles = botResponse.map(user => `${user._id}`).join("\n");
      suggestedFriends = userProfiles
        .split("\n") // Split response into lines
        .filter(line => /^[a-f0-9]{24}$/.test(line.trim())) // Extract valid MongoDB ObjectIDs (24 hex characters)
        .map(id => id.trim());

      console.log("Extracted Suggested Friends:", suggestedFriends);
    }

    

    if(isSpeakerOn){
      //User db chatbot name
      let pollyAudio = null;
      if(voice === "male"){
        pollyAudio = await bot.getPollyAudio(botResponse, "Joey");
      } else {
        pollyAudio = await bot.getPollyAudio(botResponse, "Joanna");
      }

      if (pollyAudio) {
        console.log("✅ Polly Audio Generated (Base64 MP3):", pollyAudio.substring(0, 50) + "...");
      } else {
        console.log("⚠ Polly Audio Generation Failed.");
      }

      botData = {
        senderId: "6796b051b169170b8ada7a9f",
        content: botResponse,
        details: suggestedFriends,
        entityId,
        media: pollyAudio || null,
        entity,
      };
    } else {
      botData = {
        senderId: "6796b051b169170b8ada7a9f",
        content: botResponse,
        details: suggestedFriends,
        entityId,
        media: null,
        entity,
      };
    }
   
    messageHandler.createMessage(botData);

    socket.emit("success", {
      message: "Bot response generated successfully",
      timestamp: moment().unix(),
    });

    io.to(entityId).emit("receiveMessage", {
      senderId: botData.senderId,
      content: botData.content,
      media: botData.media,
      timestamp: moment().unix(),
      entity: botData.entity,
      isBot: true,
      suggestedFriends: suggestedFriends,
    });
  } catch (error) {
    console.error("Error processing bot message:", error);
    socket.emit("error", { message: "Bot response failed" });
  }
};

module.exports = bot;
