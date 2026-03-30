import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * 餐廳指派演算法
 *
 * 根據群組成員的預算偏好和飲食限制，從 restaurants collection 中
 * 篩選並隨機指派一家合適的餐廳。
 *
 * 篩選順序：
 * 1. 城市 + 區域
 * 2. 預算等級（取群組中位數）
 * 3. 飲食限制（必須满足所有成員）
 * 4. 排除近 2 週已指派給相同成員的餐廳
 * 5. 隨機選一家
 */

export interface AssignmentResult {
    restaurantId: string;
    restaurantName: string;
    restaurantAddress: string;
    restaurantLocation: admin.firestore.GeoPoint;
    restaurantPhone: string;
    restaurantImageUrl: string | null;
}

/**
 * 為一個 DinnerGroup 指派餐廳
 *
 * @param groupId - DinnerGroup 文檔 ID
 * @param participantIds - 群組成員 UID 列表
 * @param city - 活動城市
 * @param district - 活動區域
 */
export async function assignRestaurant(
    groupId: string,
    participantIds: string[],
    city: string,
    district: string
): Promise<AssignmentResult | null> {
    console.log(
        `[assignRestaurant] Starting for group ${groupId} in ${city} ${district}`
    );

    // 1. 取得所有成員的偏好
    const memberDocs = await Promise.all(
        participantIds.map((uid) => db.collection("users").doc(uid).get())
    );

    const budgetLevels: number[] = [];
    const allDietaryTags: Set<string> = new Set();

    for (const doc of memberDocs) {
        const data = doc.data();
        if (!data) continue;

        budgetLevels.push(data.budgetRange ?? 1);

        const dietary: string[] = data.dietaryPreferences ?? ["none"];
        for (const tag of dietary) {
            if (tag !== "none") {
                allDietaryTags.add(tag);
            }
        }
    }

    // 2. 計算預算中位數
    budgetLevels.sort((a, b) => a - b);
    const medianBudget =
        budgetLevels[Math.floor(budgetLevels.length / 2)] ?? 1;

    console.log(
        `[assignRestaurant] Budget median: ${medianBudget}, dietary: [${Array.from(allDietaryTags).join(", ")}]`
    );

    // 3. 查詢餐廳：城市 + 區域 + 預算 + 仍在合作
    let query = db
        .collection("restaurants")
        .where("city", "==", city)
        .where("district", "==", district)
        .where("budgetLevel", "==", medianBudget)
        .where("isActive", "==", true);

    let snapshot = await query.get();

    // 4. 如果找不到完全匹配預算的，擴大搜索（budget ±1）
    let candidates = snapshot.docs;
    if (snapshot.empty) {
        console.log(
            `[assignRestaurant] No exact budget match, expanding to ±1`
        );
        const expandedQuery = db
            .collection("restaurants")
            .where("city", "==", city)
            .where("district", "==", district)
            .where("isActive", "==", true);

        const expandedSnapshot = await expandedQuery.get();

        // 手動篩選 budget ±1
        candidates = expandedSnapshot.docs.filter((doc) => {
            const level = doc.data().budgetLevel ?? 1;
            return Math.abs(level - medianBudget) <= 1;
        });

        if (candidates.length === 0) {
            console.warn(
                `[assignRestaurant] No restaurants found in ${city} ${district} with budget ~${medianBudget}`
            );
            return null;
        }
    }

    // 5. 過濾飲食限制
    if (allDietaryTags.size > 0) {
        candidates = candidates.filter((doc) => {
            const restaurantTags: string[] = doc.data().dietaryTags ?? [];
            // 餐廳必須支援所有成員的飲食限制
            return Array.from(allDietaryTags).every((tag) =>
                restaurantTags.includes(tag)
            );
        });
    }

    // 如果飲食限制篩選後沒有結果，放寬到只要沒有衝突
    if (candidates.length === 0 && allDietaryTags.size > 0) {
        console.log(
            `[assignRestaurant] Relaxing dietary filter, using all budget-matched restaurants`
        );
        candidates = snapshot.docs;
    }

    // 6. 排除近 2 週已指派的餐廳
    const twoWeeksAgo = new Date();
    twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);

    const recentlyUsed = candidates.filter((doc) => {
        const lastBooked = doc.data().lastBookedAt;
        if (!lastBooked) return false;
        return lastBooked.toDate() > twoWeeksAgo;
    });

    // 如果排除後還有選擇，就用排除後的；否則用全部
    if (
        candidates.length - recentlyUsed.length > 0 &&
        recentlyUsed.length > 0
    ) {
        const recentIds = new Set(recentlyUsed.map((d) => d.id));
        candidates = candidates.filter((d) => !recentIds.has(d.id));
    }

    if (candidates.length === 0) {
        console.warn(`[assignRestaurant] No suitable restaurants found at all`);
        return null;
    }

    // 7. 隨機選一家
    const chosen = candidates[Math.floor(Math.random() * candidates.length)];
    const chosenData = chosen.data();

    console.log(
        `[assignRestaurant] Chosen: ${chosenData.name} (budget: ${chosenData.budgetLevel})`
    );

    // 8. 更新餐廳的 lastBookedAt
    await db.collection("restaurants").doc(chosen.id).update({
        lastBookedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 9. 更新 DinnerGroup 的餐廳欄位（反正規化快取）
    const result: AssignmentResult = {
        restaurantId: chosen.id,
        restaurantName: chosenData.name,
        restaurantAddress: chosenData.address,
        restaurantLocation: chosenData.location,
        restaurantPhone: chosenData.phone,
        restaurantImageUrl: chosenData.imageUrl || null,
    };

    await db.collection("dinner_groups").doc(groupId).update({
        restaurantId: result.restaurantId,
        restaurantName: result.restaurantName,
        restaurantAddress: result.restaurantAddress,
        restaurantLocation: result.restaurantLocation,
        restaurantPhone: result.restaurantPhone,
        restaurantImageUrl: result.restaurantImageUrl,
    });

    return result;
}
