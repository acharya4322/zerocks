"use strict";
/**
 * cleanupExpiredJobs — Scheduled Function
 *
 * Runs every hour as a safety net to clean up expired print jobs
 * that weren't properly handled (e.g., network failures, app crashes).
 *
 * Actions:
 * 1. Queries jobs where expiresAt < now AND status is still active
 * 2. Deletes orphaned files from Storage
 * 3. Marks jobs as expired/completed
 * 4. Limits to 100 per run to avoid timeouts
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
exports.cleanupExpiredJobs = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const logger = __importStar(require("firebase-functions/logger"));
exports.cleanupExpiredJobs = (0, scheduler_1.onSchedule)({
    schedule: "every 60 minutes",
    timeZone: "Asia/Kolkata",
    retryCount: 2,
}, async () => {
    const db = admin.firestore();
    const bucket = admin.storage().bucket();
    const now = admin.firestore.Timestamp.now();
    logger.info("Starting expired jobs cleanup...");
    // Query expired active jobs
    const expiredSnapshot = await db
        .collection("printJobs")
        .where("expiresAt", "<", now)
        .where("status", "in", [
        "uploaded",
        "inQueue",
        "printing",
        "ready",
    ])
        .limit(100)
        .get();
    if (expiredSnapshot.empty) {
        logger.info("No expired jobs found.");
        return;
    }
    let cleaned = 0;
    let errors = 0;
    for (const doc of expiredSnapshot.docs) {
        try {
            const jobId = doc.id;
            const data = doc.data();
            // Delete files from Storage
            const [files] = await bucket.getFiles({
                prefix: `printJobs/${jobId}/`,
            });
            await Promise.all(files.map((f) => f.delete()));
            // Mark as expired
            await doc.ref.update({
                status: "completed",
                fileUrl: null,
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
                statusHistory: admin.firestore.FieldValue.arrayUnion([
                    {
                        status: "expired",
                        at: admin.firestore.Timestamp.now(),
                        by: "system",
                    },
                ]),
            });
            // Decrement shop active jobs
            if (data.shopId) {
                await db.doc(`shops/${data.shopId}`).update({
                    "stats.activeJobs": admin.firestore.FieldValue.increment(-1),
                });
            }
            cleaned++;
        }
        catch (error) {
            errors++;
            logger.error(`Error cleaning job ${doc.id}:`, error);
        }
    }
    logger.info(`Cleanup complete: ${cleaned} jobs cleaned, ${errors} errors`);
});
//# sourceMappingURL=cleanupExpired.js.map