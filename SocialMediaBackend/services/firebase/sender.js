const admin = require("firebase-admin");
// Load Firebase Admin SDK credentials
// const serviceAccount = require("./awesome-e3b59-firebase-adminsdk-fbsvc-66a18ff381.json");

// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   databaseURL: "https://awesome-e3b59.firebaseio.com/",
// });

const serviceAccount = require("./bondbridge-5bb5b-firebase-adminsdk-fbsvc-a7434e9480.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://bondbridge-5bb5b.firebaseio.com/",
});


const sendPushNotification = async (data) => {

  const { dataPayload , tokens ,payload } = data;
  console.log(dataPayload)

  try {
    const results = await Promise.all(
      tokens.map(async (token) => {
        try {
          const message = {
            notification: {
              title: dataPayload.title,
              body: dataPayload.body,
            },
            data:{data: JSON.stringify(payload)},
            token: token,
          };

          const response = await admin.messaging().send(message);
          console.log(response)
          return true
        } catch (error) {
          console.error(`Error sending notification to token ${token}:`, error);
          return { token, success: false, error: error.message };
        }
      })
    );

    
    return true
  } catch (error) {
    console.error("Error sending messages:", error);
    return error
  }
};


module.exports = sendPushNotification