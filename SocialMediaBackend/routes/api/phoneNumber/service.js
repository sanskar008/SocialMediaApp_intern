const axios = require('axios');
require('dotenv').config();

const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN;
const TWILIO_FROM_NUMBER = process.env.TWILIO_FROM_NUMBER;

/**
 * Send an OTP via Twilio.
 * @param {string} phoneNumber - The recipient's phone number (without country code).
 * @param {string} countryCode - The recipient's country code (e.g., +91).
 * @param {string} otp - The OTP to be sent.
 * @returns {Promise<object>} - Twilio response object on success.
 * @throws {Error} - Throws an error if the request fails.
 */


const sendOtpViaTwilio = async (phoneNumber, countryCode, otp) => {
    try {
        const toNumber = `${countryCode}${phoneNumber}`; // Combine country code and phone number
        const response = await axios.post(
            `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`,
            new URLSearchParams({
                To: toNumber,
                From: TWILIO_FROM_NUMBER,
                Body: `Your OTP is: ${otp}`
            }),
            {
                auth: {
                    username: TWILIO_ACCOUNT_SID,
                    password: TWILIO_AUTH_TOKEN
                }
            }
        );

        return response.data;
    } catch (err) {
        console.error('Error sending OTP via Twilio:', err.response?.data || err.message);
        throw new Error('Failed to send OTP. Please try again later.');
    }
};

module.exports = {
    sendOtpViaTwilio
};
