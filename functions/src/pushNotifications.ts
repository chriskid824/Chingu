import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// admin.initializeApp() is handled in index.ts
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Trigger: 新聊天訊息推播
 *
 * 當 chatRooms/{chatRoomId}/messages/{messageId} 被寫入時，
 * 向聊天室中「非發送者」的成員推播通知。
 */
export const onNewChatMessage = functions.firestore
    .document("chatRooms/{chatRoomId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const { chatRoomId } = context.params;
        const messageData = snap.data();

        if (!messageData) return;

        const senderId: string = messageData.senderId;
        const messageText: string = messageData.text || "";
        const messageType: string = messageData.type || "text";

        // 1. 取得聊天室資訊
        const chatRoomDoc = await db
            .collection("chatRooms")
            .doc(chatRoomId)
            .get();

        if (!chatRoomDoc.exists) return;

        const chatRoomData = chatRoomDoc.data();
        if (!chatRoomData) return;

        const participants: string[] = chatRoomData.participants || chatRoomData.participantIds || [];

        // 2. 取得發送者名稱
        const senderDoc = await db.collection("users").doc(senderId).get();
        const senderName: string = senderDoc.data()?.name || "某人";

        // 3. 向其他參與者推播
        const recipientIds = participants.filter(
            (uid: string) => uid !== senderId
        );

        if (recipientIds.length === 0) return;

        // 4. 取得接收者的 FCM tokens
        const recipientDocs = await Promise.all(
            recipientIds.map((uid: string) =>
                db.collection("users").doc(uid).get()
            )
        );

        const tokens = recipientDocs
            .map((doc) => doc.data()?.fcmToken)
            .filter((token): token is string => !!token);

        if (tokens.length === 0) {
            console.log(
                `[onNewChatMessage] No FCM tokens for recipients in room ${chatRoomId}`
            );
            return;
        }

        // 5. 構建推播內容
        let bodyText: string;
        switch (messageType) {
            case "image":
                bodyText = "📷 傳了一張圖片";
                break;
            case "gif":
                bodyText = "🎥 傳了一張 GIF";
                break;
            default:
                bodyText =
                    messageText.length > 50
                        ? messageText.substring(0, 50) + "..."
                        : messageText;
        }

        const payload: admin.messaging.MulticastMessage = {
            notification: {
                title: senderName,
                body: bodyText,
            },
            data: {
                type: "new_message",
                actionType: "open_chat",
                actionData: chatRoomId,
                senderId: senderId,
                senderName: senderName,
            },
            apns: {
                payload: {
                    aps: {
                        badge: 1,
                        sound: "default",
                    },
                },
            },
            android: {
                priority: "high" as const,
                notification: {
                    channelId: "chingu_chat",
                    priority: "high" as const,
                },
            },
            tokens: tokens,
        };

        try {
            const response = await messaging.sendEachForMulticast(payload);
            console.log(
                `[onNewChatMessage] Sent ${response.successCount}/${tokens.length} notifications for room ${chatRoomId}`
            );

            // 清理無效 tokens
            if (response.failureCount > 0) {
                await cleanupInvalidTokens(
                    response,
                    tokens,
                    recipientIds,
                    recipientDocs
                );
            }
        } catch (error) {
            console.error("[onNewChatMessage] Error sending notification:", error);
        }

        // 6. 更新聊天室的未讀計數
        const unreadUpdates: Record<string, number> = {};
        for (const uid of recipientIds) {
            unreadUpdates[`unreadCount.${uid}`] =
                admin.firestore.FieldValue.increment(1) as unknown as number;
        }
        await db.collection("chatRooms").doc(chatRoomId).update(unreadUpdates);
    });

/**
 * Trigger: 互評配對成功推播
 *
 * 當 dinnerReviews/{reviewId} 被寫入時，
 * 檢查是否形成 mutual match（雙方都選「想再見面」），
 * 若是，建立聊天室並推播通知。
 */
export const onMutualMatch = functions.firestore
    .document("dinnerReviews/{reviewId}")
    .onCreate(async (snap) => {
        const reviewData = snap.data();
        if (!reviewData) return;

        const reviewerId: string = reviewData.reviewerId;
        const revieweeId: string = reviewData.revieweeId;
        const wantToMeetAgain: boolean = reviewData.wantToMeetAgain;
        const eventId: string = reviewData.eventId;
        const groupId: string = reviewData.groupId;

        // 只處理正面評價
        if (!wantToMeetAgain) return;

        // 1. 檢查對方是否也給了正面評價
        const reverseReviewSnapshot = await db
            .collection("dinnerReviews")
            .where("reviewerId", "==", revieweeId)
            .where("revieweeId", "==", reviewerId)
            .where("eventId", "==", eventId)
            .where("wantToMeetAgain", "==", true)
            .limit(1)
            .get();

        if (reverseReviewSnapshot.empty) {
            // 對方尚未評價或不想再見面
            return;
        }

        console.log(
            `[onMutualMatch] Mutual match found: ${reviewerId} <-> ${revieweeId}`
        );

        // 2. 用確定性 ID 防止 race condition（兩人同時提交評價）
        const sortedUids = [reviewerId, revieweeId].sort();
        const deterministicId = `match_${sortedUids[0]}_${sortedUids[1]}_${eventId}`;

        // 檢查是否已存在
        const existingDoc = await db.collection("chatRooms").doc(deterministicId).get();
        if (existingDoc.exists) {
            console.log(
                `[onMutualMatch] Chat room already exists: ${deterministicId}`
            );
            return;
        }

        // 3. 建立新聊天室（使用確定性 ID 防止重複）
        const chatRoomRef = db.collection("chatRooms").doc(deterministicId);
        await chatRoomRef.set({
            participants: [reviewerId, revieweeId],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessage: "你們互相想再見面！開始聊天吧 💬",
            lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageSenderId: "system",
            unreadCount: {
                [reviewerId]: 1,
                [revieweeId]: 1,
            },
            source: "mutual_match",
            eventId: eventId,
            groupId: groupId,
        });

        console.log(
            `[onMutualMatch] Chat room created: ${chatRoomRef.id}`
        );

        // 4. 寫入系統訊息
        await chatRoomRef.collection("messages").add({
            text: "🎉 恭喜！你們互相想再見面，聊天室已解鎖！",
            senderId: "system",
            type: "system",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 5. 推播通知雙方
        const [reviewerDoc, revieweeDoc] = await Promise.all([
            db.collection("users").doc(reviewerId).get(),
            db.collection("users").doc(revieweeId).get(),
        ]);

        const reviewerName: string = reviewerDoc.data()?.name || "某人";
        const revieweeName: string = revieweeDoc.data()?.name || "某人";

        const sendMatchNotification = async (
            recipientId: string,
            recipientToken: string | undefined,
            matchedName: string
        ) => {
            if (!recipientToken) return;

            const message: admin.messaging.Message = {
                notification: {
                    title: "🎉 配對成功！",
                    body: "有人也想再見你！快開始聊天吧 💬",
                },
                data: {
                    type: "mutual_match",
                    actionType: "open_chat",
                    actionData: chatRoomRef.id,
                    matchedUserId: recipientId,
                },
                apns: {
                    payload: {
                        aps: {
                            badge: 1,
                            sound: "default",
                        },
                    },
                },
                android: {
                    priority: "high" as const,
                    notification: {
                        channelId: "chingu_match",
                        priority: "high" as const,
                    },
                },
                token: recipientToken,
            };

            try {
                await messaging.send(message);
                console.log(
                    `[onMutualMatch] Notification sent to ${recipientId}`
                );
            } catch (error) {
                console.error(
                    `[onMutualMatch] Error sending to ${recipientId}:`,
                    error
                );
            }
        };

        await Promise.all([
            sendMatchNotification(
                reviewerId,
                reviewerDoc.data()?.fcmToken,
                revieweeName
            ),
            sendMatchNotification(
                revieweeId,
                revieweeDoc.data()?.fcmToken,
                reviewerName
            ),
        ]);

        // 6. 更新雙方的 totalMatches
        await Promise.all([
            db
                .collection("users")
                .doc(reviewerId)
                .update({
                    totalMatches: admin.firestore.FieldValue.increment(1),
                }),
            db
                .collection("users")
                .doc(revieweeId)
                .update({
                    totalMatches: admin.firestore.FieldValue.increment(1),
                }),
        ]);
    });

/**
 * Helper: 清理無效的 FCM tokens
 */
async function cleanupInvalidTokens(
    response: admin.messaging.BatchResponse,
    tokens: string[],
    recipientIds: string[],
    recipientDocs: admin.firestore.DocumentSnapshot[]
) {
    const invalidTokens: string[] = [];

    response.responses.forEach(
        (resp: admin.messaging.SendResponse, idx: number) => {
            if (!resp.success) {
                const errorCode = resp.error?.code;
                if (
                    errorCode === "messaging/invalid-registration-token" ||
                    errorCode === "messaging/registration-token-not-registered"
                ) {
                    invalidTokens.push(tokens[idx]);
                }
            }
        }
    );

    if (invalidTokens.length > 0) {
        console.log(
            `[FCM Cleanup] Removing ${invalidTokens.length} invalid tokens`
        );

        for (const doc of recipientDocs) {
            const token = doc.data()?.fcmToken;
            if (token && invalidTokens.includes(token)) {
                await db.collection("users").doc(doc.id).update({
                    fcmToken: admin.firestore.FieldValue.delete(),
                });
            }
        }
    }
}
