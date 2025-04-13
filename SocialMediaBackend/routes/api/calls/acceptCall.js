const callService = require('./service');
const { calls : callsMongo } = require('../../../db/mongo');

const acceptCall = {};

acceptCall.validateBody = (req, res, next) => {
    const { callId } = req.body;

    try {

        if (!callId) {
            return res.status(400).json({ message: 'Call ID is required.' });
        }

        next();
    } catch (error) {
        console.error('Validation Error:', error.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

acceptCall.validateCall = async (req, res, next) => {
    const { callId } = req.body;
    const userId = req.userId;

    try {

        const callData = await callsMongo.instance.getCallById(callId);
        if (!callData) {
            return res.status(404).json({ message: 'Call not found.' });
        }

        if (!['ongoing', 'ringing'].includes(callData.status)) {
            return res.status(400).json({ message: 'The call is no longer active.' });
        }

        const isToUser = callData.to === userId;
        const isParticipant = callData.participants?.some((participant) => participant.userId === userId);

        if (!isToUser && !isParticipant) {
            return res.status(403).json({ message: 'You are not authorized to accept this call.' });
        }

        req.callData = callData;

        next();
    } catch (error) {
        console.error('Call Validation Error:', error.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

acceptCall.acceptCall = async (req, res) => {
    const { callData } = req;
    const userId = req.userId;

    try {

        const token = await callService.generateAgoraToken(callData.channelName, userId);

        if (callData.participants?.length) {
            await callsMongo.instance.updateParticipantStatus(callData._id, userId, 'joined');
        }

        return res.status(200).json({
            message: 'Call accepted successfully.',
            token,
            channelName: callData.channelName,
        });
    } catch (error) {
        console.error('Accept Call Error:', error.message);
        return res.status(500).json({ message: 'Failed to accept call.' });
    }
};

module.exports = acceptCall;
