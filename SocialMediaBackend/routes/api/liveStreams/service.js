require('dotenv').config()
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

const appID = process.env.AGORA_APP_ID
const appCertificate = process.env.AGORA_APP_CERTIFICATE

const agoraService = {};

/**
 * Generate an Agora token
 * @param {string} channelName - The name of the channel
 * @param {string} userId - The user ID for whom the token is generated
 * @param {string} role - The role of the user in the channel (PUBLISHER or SUBSCRIBER)
 * @param {number} expireTime - The token expiration time in seconds (default: 3600)
 * @returns {string} Agora token
 */
agoraService.generateAgoraToken = (channelName, userId, role = RtcRole.PUBLISHER, expireTime = 3600) => {
    try {
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpireTime = currentTimestamp + expireTime;

        return RtcTokenBuilder.buildTokenWithAccount(
            appID,
            appCertificate,
            channelName,
            0,
            role,
            privilegeExpireTime
        );
    } catch (error) {
        console.error("Agora Token Generation Error:", error.message);
        throw new Error("Failed to generate Agora token.");
    }
};

module.exports = agoraService;
