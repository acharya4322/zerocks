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

import {
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const onJobStatusChanged = onDocumentUpdated(
  "printJobs/{jobId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logger.warn("onJobStatusChanged: Missing data");
      return;
    }

    const beforeStatus = beforeData.status as string;
    const afterStatus = afterData.status as string;

    // Only process when status changes TO 'completed' or 'cancelled'
    if (beforeStatus === afterStatus) return;
    if (afterStatus !== "completed" && afterStatus !== "cancelled") return;
    // Prevent re-triggering
    if (beforeStatus === "completed" || beforeStatus === "cancelled") return;

    const jobId = event.params.jobId;
    const shopId = afterData.shopId as string;
    const userId = afterData.userId as string;
    const fileName = afterData.fileName as string;

    logger.info(`Job ${jobId} → ${afterStatus}`);

    // 1. Delete all files from Storage
    try {
      const bucket = admin.storage().bucket();
      const [files] = await bucket.getFiles({
        prefix: `printJobs/${jobId}/`,
      });

      if (files.length > 0) {
        await Promise.all(files.map((f) => f.delete()));
        logger.info(
          `Deleted ${files.length} files for job ${jobId}`
        );
      }
    } catch (error) {
      logger.error("Error deleting files:", error);
    }

    // 2. Clear fileUrl in Firestore
    try {
      await event.data!.after.ref.update({ fileUrl: null });
    } catch (error) {
      logger.error("Error clearing fileUrl:", error);
    }

    // 3. Send FCM notification to customer
    if (afterStatus === "completed") {
      try {
        const db = admin.firestore();
        const userDoc = await db.doc(`users/${userId}`).get();
        const fcmToken = userDoc.data()?.fcmToken as string | undefined;

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
      } catch (error) {
        logger.error("Error sending FCM to customer:", error);
      }
    }

    // 4. Update shop stats
    try {
      const db = admin.firestore();
      const statsUpdate: Record<string, unknown> = {
        "stats.activeJobs": admin.firestore.FieldValue.increment(-1),
      };

      if (afterStatus === "completed") {
        statsUpdate["stats.totalJobs"] =
          admin.firestore.FieldValue.increment(1);
      }

      await db.doc(`shops/${shopId}`).update(statsUpdate);
    } catch (error) {
      logger.error("Error updating shop stats:", error);
    }
  }
);
