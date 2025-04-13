const jwt = require('jsonwebtoken');
const ssoHelper = require('../../routes/api/sso');
const auth = {}

auth.socket = async(socket, next) => {
    const jwtToken = socket.handshake.auth.token; // Token from the client
    const secretKey = process.env.JWT_CHAT_SECRET;
    let userId;
    let status;

    jwt.verify(jwtToken, secretKey, (err, decoded) => {
        if (err) {
          console.error('Token is not valid:', err.message);
          return next(new Error('Authentication error: Invalid token'));
        } else {
            userId = decoded?.id;
            status = decoded?.status
        }
    });

    try {
        //verification from redis
        const isMatch = await ssoHelper.verifySocketToken( jwtToken , userId);
        if ( !isMatch ) {
            return next(new Error('Authentication error: Invalid token'));
        }

        socket.user = userId
        socket.status = status
        next();
    } catch (error) {
        console.error('Socket authentication failed:', error.message);
        next(new Error('Authentication error: Invalid token'));
    }
}

module.exports = auth;
