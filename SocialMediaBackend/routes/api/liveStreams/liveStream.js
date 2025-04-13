const { instance: LiveStreams } = require("../../../db/mongo/liveStreams");
const { generateAgoraToken } = require("./service"); // Agora service for token generation
const { v4: uuidv4 } = require("uuid");

const liveStream = {};

// Validate request body for starting a live stream
liveStream.validateStartLiveBody = (req, res, next) => {
    const { userId } = req;

    try {
        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }
        next();
    } catch (error) {
        console.error("Validation Error:", error.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

liveStream.startLiveStream = async (req, res) => {
    const { userId } = req;

    try {
        const existingLiveStream = await LiveStreams.getLiveStreamByUserId(userId);

        if (existingLiveStream && existingLiveStream.isLive) {
            const token = generateAgoraToken(existingLiveStream.channelName, userId);
            return res.status(200).json({
                message: "Live stream already active.",
                channelName: existingLiveStream.channelName,
                token,
            });
        }

        const channelName = uuidv4();
        const token = generateAgoraToken(channelName, userId);

        await LiveStreams.startLiveStream({ userId, channelName });

        return res.status(200).json({
            message: "Live stream started successfully.",
            channelName,
            token,
        });
    } catch (error) {
        console.error("Start Live Stream Error:", error.message);
        return res.status(500).json({ message: "Failed to start live stream." });
    }
};

// Validate request body for ending a live stream
liveStream.validateEndLiveBody = (req, res, next) => {
    const { userId } = req;

    try {
        if (!userId) {
            return res.status(400).json({ message: "User ID is required." });
        }
        next();
    } catch (error) {
        console.error("Validation Error:", error.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

// End a live stream
liveStream.endLiveStream = async (req, res) => {
    const { userId } = req;

    try {
        await LiveStreams.endLiveStream(userId);

        return res.status(200).json({ message: "Live stream ended successfully." });
    } catch (error) {
        console.error("End Live Stream Error:", error.message);
        return res.status(500).json({ message: "Failed to end live stream." });
    }
};

liveStream.validateJoinLiveBody = (req, res, next) => {
    const { userId } = req.body;

    try {
        if (!userId) {
            return res.status(400).json({ message: "User ID is required to join the live stream." });
        }
        if (userId == req.userId) {
            return res.status(400).json({ message: "Cant Join own stream as a member." });
        }
        req.liveStreamUserId = userId;
        next();
    } catch (error) {
        console.error("Validation Error:", error.message);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

liveStream.checkLiveStreamStatus = async (req, res, next) => {
    const { liveStreamUserId } = req;

    try {
        const liveStream = await LiveStreams.getLiveStreamByUserId(liveStreamUserId);

        if (!liveStream || !liveStream.isLive) {
            return res.status(404).json({ message: "The live stream is not active." });
        }

        req.liveStreamDetails = liveStream;
        next();
    } catch (error) {
        console.error("Live Stream Status Error:", error.message);
        return res.status(500).json({ message: "Failed to check live stream status." });
    }
};

// Generate a token for joining the live stream
liveStream.generateTokenForLiveStream = async (req, res) => {
    const { liveStreamDetails } = req;
    const { userId: joiningUserId } = req;

    try {
        const token = generateAgoraToken(liveStreamDetails.channelName, joiningUserId);

        return res.status(200).json({
            message: "Live stream token generated successfully.",
            channelName: liveStreamDetails.channelName,
            token,
            userId: liveStreamDetails.userId,
        });
    } catch (error) {
        console.error("Token Generation Error:", error.message);
        return res.status(500).json({ message: "Failed to generate token for live stream." });
    }
};


module.exports = liveStream;
