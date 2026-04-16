/**
 * 管理員權限規則測試
 *
 * 需要 Firestore Emulator 正在運行：
 *   firebase emulators:start --only firestore --project demo-chingu
 *
 * 驗證 firestore.rules 中 isAdmin() / isDeveloper() 的核心行為：
 *   1. 一般用戶無法寫入受保護的集合（restaurants / icebreaker_questions）
 *   2. /admins/{uid} 中註冊的用戶可寫入受保護的集合
 *   3. 一般用戶無法管理 /admins collection（只有 super-admin 可）
 */

import {
    initializeTestEnvironment,
    RulesTestEnvironment,
    assertFails,
    assertSucceeds,
} from "@firebase/rules-unit-testing";
import * as fs from "fs";
import * as path from "path";

const PROJECT_ID = "demo-chingu";
const SUPER_ADMIN_EMAIL = "chriskid824@gmail.com";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
        projectId: PROJECT_ID,
        firestore: {
            rules: fs.readFileSync(
                path.resolve(__dirname, "../../firestore.rules"),
                "utf8"
            ),
            host: "127.0.0.1",
            port: 8080,
        },
    });
});

afterAll(async () => {
    if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
    if (testEnv) await testEnv.clearFirestore();
});

jest.setTimeout(30000);

describe("管理員權限 (firestore.rules)", () => {
    test("一般用戶不能寫入 /restaurants — 應被 rules 拒絕", async () => {
        const normalUser = testEnv.authenticatedContext("normalUserUid", {
            email: "alice@example.com",
        });

        await assertFails(
            normalUser
                .firestore()
                .collection("restaurants")
                .doc("rest_001")
                .set({
                    name: "惡意餐廳",
                    address: "假地址",
                    isActive: true,
                })
        );
    });

    test("註冊在 /admins/{uid} 的用戶可寫入 /restaurants", async () => {
        const adminUid = "opsAdminUid";

        // Bootstrap：用 withSecurityRulesDisabled 直接寫入 /admins
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            await ctx.firestore().collection("admins").doc(adminUid).set({
                addedAt: new Date(),
                addedBy: "super_admin_seed",
                role: "ops",
                note: "測試用營運管理員",
            });
        });

        const adminUser = testEnv.authenticatedContext(adminUid, {
            email: "ops@example.com",
        });

        await assertSucceeds(
            adminUser
                .firestore()
                .collection("restaurants")
                .doc("rest_002")
                .set({
                    name: "正當餐廳",
                    address: "信義區市府路 1 號",
                    isActive: true,
                })
        );
    });

    test("一般用戶不能管理 /admins collection — 防止權限自我提升", async () => {
        const attackerUid = "attackerUid";

        // 攻擊者就算先寫了自己進 /admins 也不行（rules 會擋）
        const attacker = testEnv.authenticatedContext(attackerUid, {
            email: "attacker@example.com",
        });

        await assertFails(
            attacker.firestore().collection("admins").doc(attackerUid).set({
                addedAt: new Date(),
                addedBy: "self",
                role: "super",
            })
        );

        // Super-admin (硬編碼 email) 才可以
        const superAdmin = testEnv.authenticatedContext("superAdminUid", {
            email: SUPER_ADMIN_EMAIL,
        });

        await assertSucceeds(
            superAdmin
                .firestore()
                .collection("admins")
                .doc("newOpsUid")
                .set({
                    addedAt: new Date(),
                    addedBy: "superAdminUid",
                    role: "ops",
                })
        );
    });
});
