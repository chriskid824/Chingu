import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Use existing app initialization if available, otherwise initialize
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/**
 * 創建每週活動
 * 定時觸發: 每週一 00:00 (Asia/Taipei)
 * 目標: 自動創建下週三、五、日的活動
 */
export const createWeeklyEvents = functions.pubsub
  .schedule("0 0 * * 1") // Every Monday at 00:00
  .timeZone("Asia/Taipei")
  .onRun(async (context) => {
    const db = admin.firestore();
    const batch = db.batch();

    // 定義要創建的城市和區域
    const locations = [
      { city: "台北市", districts: ["信義區", "大安區", "中山區"] },
      { city: "台中市", districts: ["西屯區", "西區"] },
      { city: "高雄市", districts: ["左營區", "前金區"] },
    ];

    // 計算下週的日期 (週三, 週五, 週日)
    const now = new Date();
    // Move to next Monday (if today is Monday, this logic depends on run time, assuming running on Monday)
    // Actually, if running on Monday, "next Wednesday" is current week Wednesday?
    // Requirement says "下週三/五/日". If today is Monday Jan 1, Next Week Wed is Jan 10.
    // Let's assume we want to create events for the *following* week to give people time to register.

    // Calculate start of next week (Next Monday)
    const daysUntilNextMonday = (1 + 7 - now.getDay()) % 7 || 7;
    const nextMonday = new Date(now);
    nextMonday.setDate(now.getDate() + daysUntilNextMonday);

    const targetDays = [
        { name: "Wednesday", offset: 2 }, // Mon + 2 = Wed
        { name: "Friday", offset: 4 },    // Mon + 4 = Fri
        { name: "Sunday", offset: 6 }     // Mon + 6 = Sun
    ];

    const eventDates = targetDays.map(day => {
        const d = new Date(nextMonday);
        d.setDate(nextMonday.getDate() + day.offset);
        d.setHours(19, 0, 0, 0); // 19:00
        return d;
    });

    // 隨機或循環選擇餐廳 (這裡是簡化版，隨機生成)
    // 實際上應該從 event_templates 讀取

    try {
        const templatesSnapshot = await db.collection("event_templates").get();
        const templates = templatesSnapshot.docs.map(doc => doc.data());

        for (const loc of locations) {
            for (const district of loc.districts) {
                // Filter templates for this location, or use default
                const districtTemplates = templates.filter(t => t.city === loc.city && t.district === district);

                for (const date of eventDates) {
                    const eventRef = db.collection("dinner_events").doc();

                    // Pick a random template or default
                    let template = null;
                    if (districtTemplates.length > 0) {
                        template = districtTemplates[Math.floor(Math.random() * districtTemplates.length)];
                    }

                    const eventData = {
                        creatorId: "system",
                        dateTime: admin.firestore.Timestamp.fromDate(date),
                        budgetRange: 1, // Default 500-800
                        city: loc.city,
                        district: district,
                        maxParticipants: 6,
                        currentParticipants: 0,
                        participantIds: [],
                        participantStatus: {},
                        waitlist: [],
                        status: "pending",
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        icebreakerQuestions: template ? template.icebreakerQuestions : [
                            "如果可以和世界上任何人共進晚餐，你會選誰？",
                            "最近一次讓你開懷大笑的事情是什麼？",
                            "你最喜歡的旅行經歷是什麼？"
                        ],
                        restaurantName: template ? template.restaurantName : null,
                        // ... other fields
                    };

                    batch.set(eventRef, eventData);
                }
            }
        }

        await batch.commit();
        console.log("Weekly events created successfully.");
        return null;
    } catch (error) {
        console.error("Error creating weekly events:", error);
        return null;
    }
  });
