// const functions = require("firebase-functions/v1");
// const admin = require("firebase-admin");

// admin.initializeApp();

// // Updated function definition
// exports.sendPushNotification = functions
//     .region("us-central1")
//     .https.onCall(async (data, context) => {
//     // Validate request
//       if (!data.token) {
//         throw new functions.https.HttpsError(
//             "invalid-argument",
//             "The function must be called with a device token",
//         );
//       }

//       try {
//         const message = {
//           token: data.token,
//           notification: {
//             title: data.title || "Default Title",
//             body: data.body || "Default Body",
//           },
//           android: {
//             priority: "high",
//             notification: {
//               sound: "default",
//               channelId: "high_importance_channel",
//             },
//           },
//           apns: {
//             payload: {
//               aps: {
//                 sound: "default",
//                 badge: 1,
//               },
//             },
//           },
//           webpush: {
//             headers: {
//               Urgency: "high",
//             },
//           },
//         };

//         const response = await admin.messaging().send(message);

//         return {
//           success: true,
//           messageId: response,
//         };
//       } catch (error) {
//         console.error("Error sending message:", error);
//         throw new functions.https.HttpsError(
//             "internal",
//             "Failed to send notification",
//             error.message,
//         );
//       }
//     });
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotification = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
      const {token, title = "Default Title", body = "Default Body"} = data;

      if (!token) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with a device token",
        );
      }

      const message = {
        token,
        notification: {title, body},
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "high_importance_channel",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
        webpush: {
          headers: {
            Urgency: "high",
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        return {
          success: true,
          messageId: response,
        };
      } catch (error) {
        console.error("Error sending message:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification",
            error.message,
        );
      }
    });
