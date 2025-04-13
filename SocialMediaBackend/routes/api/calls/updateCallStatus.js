const { instance: Calls } = require('../../../db/mongo/calls');
const callNotification = require('../../notifications/call');

const updateCallStatus = {};

updateCallStatus.validateBody = (req, res, next) => {
    try {
        const { callId, status } = req.body;

        if (!callId || !status) {
            return res.status(400).json({ message: 'Call ID and status are required.' });
        }

        if (!['missed', 'ongoing', 'ended'].includes(status)) {
            return res.status(400).json({ message: 'Invalid call status.' });
        }

        next();
    } catch (error) {
        console.error('Validation Error:', error.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

updateCallStatus.update = async (req, res) => {
    try {
        const { callId, status } = req.body;

        const updatedCall = await Calls.updateParticipantStatus(callId , req.userId , status);

       if (status != "ongoing")  callNotification.send({call:updatedCall , status , callId , receiverId : req.userId});

        return res.status(200).json({ message: 'Call status updated successfully.' });
    } catch (error) {
        console.error('Update Call Status Error:', error.message);
        return res.status(500).json({ message: 'Failed to update call status.' });
    }
};

module.exports = updateCallStatus;
