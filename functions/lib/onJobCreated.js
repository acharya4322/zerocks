"use strict";
/**
 * onJobCreated — Firestore trigger
 *
 * Fires when a new document is created in `printJobs/{jobId}`.
 *
 * Actions:
 * 1. Sets `expiresAt` = createdAt + 24 hours (for TTL cleanup)
 * 2. Sends FCM push notification to the shop owner
 * 3. Increments the shop's `stats.activeJobs` counter
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onJobCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const logger = __importStar(require("firebase-functions/logger"));
exports.onJobCreated = (0, firestore_1.onDocumentCreated)("printJobs/{jobId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        logger.warn("onJobCreated: No data in event");
        return;
    }
    const jobId = event.params.jobId;
    const data = snapshot.data();
    const shopId = data.shopId;
    const fileName = data.fileName;
    const copies = data.copies || 1;
    logger.info(`New job created: ${jobId} for shop ${shopId}`);
    const db = admin.firestore();
    // 1. Set expiresAt (24 hours from now)
    const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 24 * 60 * 60 * 1000));
    await snapshot.ref.update({
        expiresAt,
        statusHistory: admin.firestore.FieldValue.arrayUnion([
            {
                status: "uploaded",
                at: admin.firestore.Timestamp.now(),
            },
        ]),
    });
    // 2. Send FCM notification to shop
    try {
        const shopDoc = await db.doc(`shops/${shopId}`).get();
        if (!shopDoc.exists) {
            logger.warn(`Shop ${shopId} not found`);
            return;
        }
        const shopData = shopDoc.data();
        const fcmToken = shopData.fcmToken;
        const shopName = shopData.name;
        // Also update the job with the shop name (denormalization)
        await snapshot.ref.update({ shopName });
        if (fcmToken) {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: "New Print Job! 📄",
                    body: `${fileName} — ${copies} ${copies === 1 ? "copy" : "copies"}`,
                },
                data: {
                    jobId,
                    type: "new_job",
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                        channelId: "print_jobs",
                    },
                },
            });
            logger.info(`FCM sent to shop ${shopId}`);
        }
        else {
            logger.warn(`Shop ${shopId} has no FCM token`);
        }
    }
    catch (error) {
        logger.error("Error sending FCM to shop:", error);
    }
    // 3. Increment shop active jobs counter
    try {
        await db.doc(`shops/${shopId}`).update({
            "stats.activeJobs": admin.firestore.FieldValue.increment(1),
        });
    }
    catch (error) {
        logger.error("Error updating shop stats:", error);
    }
});
//# sourceMappingURL=onJobCreated.js.map