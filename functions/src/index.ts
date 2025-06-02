import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Always initialize the Admin SDK at the top level:
admin.initializeApp();

// Your callable function goes here:
export const sendAlertToCaretaker =
functions.https.onCall(async (data, context) => {
  const patientTopic = data.data.topic as string;
  const message: admin.messaging.Message = {
    topic: patientTopic,
    notification: {
      title: "🚨 Emergency Alert!",
      body: "Your patient has requested help.",
    },
    data: {
      timestamp: Date.now().toString(),
      patientId: patientTopic,
    },
  };
  try {
    const response = await admin.messaging().send(message);
    console.log("Message sent to topic:", patientTopic, response);
    return {success: true};
  } catch (err : any) {
    console.error("Error sending message:", err);
    return {success: false, error: err.toString()};
  }
});
