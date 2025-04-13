const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const appID = '12101186b472490e8c4ce45b2c405498';
const appCertificate = '0efb39c7af824f9b8315fcbe9a66d84a';

const callService = {};

callService.generateAgoraToken = async (channelName, userId) => {
    try {
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpireTime = currentTimestamp + 3600; 

        return RtcTokenBuilder.buildTokenWithAccount(
            appID,
            appCertificate,
            channelName,
            0,
            RtcRole.PUBLISHER,
            privilegeExpireTime
        );
    } catch (error) {
        console.error('Agora Token Generation Error:', error.message);
        throw new Error('Failed to generate Agora token.');
    }
};

module.exports = callService;
