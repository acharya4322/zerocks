"use strict";
/**
 * onJobStatusChanged — Firestore trigger
 *
 * Fires when a `printJobs/{jobId}` document is updated.
 * Specifically handles the transition TO 'completed' status.
 *
 * Actions:
 * 1. Deletes ALL files for this job from Firebase Storage
 * 2. Clears the `fileUrl` field in Firestore
 * 3. Sends FCM notification to the customer ("Your print is ready!")
 * 4. Updates shop stats (increment totalJobs, decrement activeJobs)
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
exports.onJobStatusChanged = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const logger = __importStar(require("firebase-functions/logger"));
exports.onJobStatusChanged = (0, firestore_1.onDocumentUpdated)("printJobs/{jobId}", async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) {
        logger.warn("onJobStatusChanged: Missing data");
        return;
    }
    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;
    // Only process when status changes TO 'completed' or 'cancelled'
    if (beforeStatus === afterStatus)
        return;
    if (afterStatus !== "completed" && afterStatus !== "cancelled")
        return;
    // Prevent re-triggering
    if (beforeStatus === "completed" || beforeStatus === "cancelled")
        return;
    const jobId = event.params.jobId;
    const shopId = afterData.shopId;
    const userId = afterData.userId;
    const fileName = afterData.fileName;
    logger.info(`Job ${jobId} → ${afterStatus}`);
    // 1. Delete all files from Storage
    try {
        const bucket = admin.storage().bucket();
        const [files] = await bucket.getFiles({
            prefix: `printJobs/${jobId}/`,
        });
        if (files.length > 0) {
            await Promise.all(files.map((f) => f.delete()));
            logger.info(`Deleted ${files.length} files for job ${jobId}`);
        }
    }
    catch (error) {
        logger.error("Error deleting files:", error);
    }
    // 2. Clear fileUrl in Firestore
    try {
        await event.data.after.ref.update({ fileUrl: null });
    }
    catch (error) {
        logger.error("Error clearing fileUrl:", error);
    }
    // 3. Send FCM notification to customer
    if (afterStatus === "completed") {
        try {
            const db = admin.firestore();
            const userDoc = await db.doc(`users/${userId}`).get();
            const fcmToken = userDoc.data()?.fcmToken;
            if (fcmToken) {
                await admin.messaging().send({
                    token: fcmToken,
                    notification: {
                        title: "Print Ready! 🖨️",
                        body: `Your document "${fileName}" is ready for pickup.`,
                    },
                    data: {
                        jobId,
                        type: "job_completed",
                    },
                    android: {
                        priority: "high",
                        notification: {
                            sound: "default",
                            channelId: "print_status",
                        },
                    },
                });
                logger.info(`FCM sent to customer ${userId}`);
            }
        }
        catch (error) {
            logger.error("Error sending FCM to customer:", error);
        }
    }
    // 4. Update shop stats
    try {
        const db = admin.firestore();
        const statsUpdate = {
            "stats.activeJobs": admin.firestore.FieldValue.increment(-1),
        };
        if (afterStatus === "completed") {
            statsUpdate["stats.totalJobs"] =
                admin.firestore.FieldValue.increment(1);
        }
        await db.doc(`shops/${shopId}`).update(statsUpdate);
    }
    catch (error) {
        logger.error("Error updating shop stats:", error);
    }
});
//# sourceMappingURL=onJobCompleted.js.map