import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function to send chat notifications.
 * Triggered by the client after sending a message.
 */
export const sendChatNotification = functions.https.onCall(async (data, context) => {
    // 1. Verify Authentication
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "User must be authenticated to send notifications."
        );
    }

    const { chatRoomId, senderName, messageContent, messageType } = data;
    const senderId = context.auth.uid; // Use authenticated user ID as sender

    // Validate required fields
    if (!chatRoomId || !messageContent) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "Missing required fields."
        );
    }

    try {
        // 2. Get Chat Room to find the recipients
        const chatRoomDoc = await admin.firestore().collection("chat_rooms").doc(chatRoomId).get();

        if (!chatRoomDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Chat room not found.");
        }

        const participantIds = chatRoomDoc.data()?.participantIds as string[];
        if (!participantIds || participantIds.length < 2) {
             console.log("Chat room has insufficient participants.");
             return { success: false, reason: "insufficient_participants" };
        }

        // Identify recipients (everyone except the sender)
        const recipientIds = participantIds.filter((id) => id !== senderId);

        if (recipientIds.length === 0) {
            console.log("No recipients found in chat room.");
            return { success: false, reason: "no_recipients" };
        }

        // 3. Get Recipients' FCM Tokens
        // We can do this in parallel
        const recipientDocs = await Promise.all(
            recipientIds.map(id => admin.firestore().collection("users").doc(id).get())
        );

        const tokens: string[] = [];
        recipientDocs.forEach(doc => {
            const token = doc.data()?.fcmToken;
            if (token) {
                tokens.push(token);
            }
        });

        if (tokens.length === 0) {
            console.log("No FCM tokens found for recipients.");
            return { success: false, reason: "no_fcm_tokens" };
        }

        // 4. Construct Notification Body
        let bodyText = messageContent;

        // Handle different message types
        if (messageType === "image") {
            bodyText = "📷 傳送了一張圖片";
        } else if (messageType === "sticker") {
            bodyText = "😊 傳送了一個貼圖";
        } else {
             // Truncate text messages to 20 chars
            if (bodyText.length > 20) {
                bodyText = bodyText.substring(0, 20) + "...";
            }
        }

        // 5. Send Notification (Multicast)
        const message = {
            tokens: tokens, // Use tokens array for multicast
            notification: {
                title: senderName || "新訊息",
                body: bodyText,
            },
            data: {
                type: "chat_message",
                chatRoomId: chatRoomId,
                senderId: senderId,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high" as const,
                notification: {
                    channelId: "chat_messages",
                    // No tag to allow stacking or unique tagging could be implemented
                }
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: senderName || "新訊息",
                            body: bodyText,
                        },
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        };

        const response = await admin.messaging().sendEachForMulticast(message);

        console.log(`Successfully sent ${response.successCount} messages; failed ${response.failureCount}.`);

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount
        };

    } catch (error) {
        console.error("Error sending chat notification:", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to send notification.",
            error
        );
    }
});
