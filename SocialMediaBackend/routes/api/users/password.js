const bcrypt = require('bcryptjs'); // You can install bcryptjs for password hashing
const { users: usersMongo } = require('../../../db/mongo');
const { users: userRedis } = require('../../../db/redis');
const { FIELDS : USER_FIELDS , FIELD_VALUES : USER_FIELD_VALUES } = require('../../../db/mongo/users');
const password = {};

// password validation (e.g., length, complexity) can be added here
password.validateSetPasswordRequestBody = (req, res, next) => {
    const { password } = req.body;

    // Check if password is provided
    if (!password) {
        return res.status(400).json({ message: 'password is required.' });
    }

    // Optionally, you can add more complex password validation, e.g., min length, complexity.
    if (password.length < 6) {
        return res.status(400).json({ message: 'password must be at least 6 characters long.' });
    }

    req.password = password; // Attach password to the request object
    next();
};

// Hash the password and store it in MongoDB and Redis
password.setNewPassword = async (req, res, next) => {
    const { phoneNumber,countryCode } = req.body;  // Assume userId is available from req
    const { password } = req.body; // The password validated earlier
    let userDetails;

    try {
        // Hash the password using bcrypt
        const hashedPassword = await bcrypt.hash(password, 10); // Salt rounds = 10

        if ( phoneNumber ){
            userDetails = await usersMongo.instance.getUserDetailsFromMobile(phoneNumber , countryCode);
        }
        else if ( req.userId ){
            userDetails = await usersMongo.instance.getUserDetailsFromId(req.userId);
        }
        else{
           return res.status(400).json({ message: 'Wrong fields provided to change password' });
        }

        req.userId = userDetails._id;
        userId = req.userId;

        const updateObj = {
            [USER_FIELDS.PASSWORD]: hashedPassword
        };

        // Only include the statusCode update if the current status is not 'PROFILE_SET'
        if (userDetails[USER_FIELDS.STATUS_CODE] !== USER_FIELD_VALUES[USER_FIELDS.STATUS_CODE].PROFILE_SET) {
            updateObj[USER_FIELDS.STATUS_CODE] = USER_FIELD_VALUES[USER_FIELDS.STATUS_CODE].PASSWORD_SET;
        }
        const updateResult = await usersMongo.instance.updateUser(userId,  updateObj );

        if (!updateResult) {
            return res.status(404).json({ message: 'User not found.' });
        }

       await userRedis.setUserDetails(userId , updateResult);

        return res.status(200).json({ message: 'password updated successfully.' });
    } catch (err) {
        console.error('Error setting new password:', err.message);
        next({ status: 500, message: 'Internal Server Error' });
    }
};


// Validate the request body (ensure old password, new password, phoneNumber, and countryCode are provided)
password.validateResetPasswordRequestBody = async (req, res, next) => {
    const { oldPassword, password, phoneNumber, countryCode } = req.body;

    // Ensure both oldPassword and new password are provided
    if (!oldPassword || !password || !phoneNumber || !countryCode) {
        return res.status(400).json({ message: 'Old password, new password, mobile number, and country code are required.' });
    }

    // Optionally, you can add more complex password validation for the new password (e.g., min length)
    if (password.length < 6) {
        return res.status(400).json({ message: 'New password must be at least 6 characters long.' });
    }

    if ( oldPassword == password ){
        return res.status(400).json({ message: 'New password cant be set as Old' });
    }

    req.oldPassword = oldPassword; // Attach old password to request object
    req.password = password; // Attach new password to request object
    req.phoneNumber = phoneNumber; // Attach mobile number to request object
    req.countryCode = countryCode; // Attach country code to request object
    next(); // Proceed to the next middleware (password verification)
};

// Verify the old password provided by the user
password.verifyOldPassword = async (req, res, next) => {
    const { oldPassword, phoneNumber, countryCode } = req; // Get old password, mobile, and country code
    try {
        // Step 1: Get the userId from MongoDB using phoneNumber and countryCode
        const userDetails = await usersMongo.instance.getUserDetailsFromMobile(phoneNumber, countryCode);

        if (!userDetails) {
            return res.status(404).json({ message: 'User not found.' });
        }

        // Step 3: Compare the provided old password with the stored password
        const isMatch = await bcrypt.compare(oldPassword, userDetails[USER_FIELDS.PASSWORD]);
        if (!isMatch) {
            return res.status(400).json({ message: 'Incorrect old password.' });
        }

        // Store the user details in the request object for updating the password later
        req.userId = userDetails._id; // Store the full user details to update password later
        next(); // Proceed to the next step (set the new password)
    } catch (err) {
        console.error('Error verifying old password:', err.message);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};


module.exports = password;
