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

import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const cleanupExpiredJobs = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: "Asia/Kolkata",
    retryCount: 2,
  },
  async () => {
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
            "stats.activeJobs":
              admin.firestore.FieldValue.increment(-1),
          });
        }

        cleaned++;
      } catch (error) {
        errors++;
        logger.error(`Error cleaning job ${doc.id}:`, error);
      }
    }

    logger.info(
      `Cleanup complete: ${cleaned} jobs cleaned, ${errors} errors`
    );
  }
);
