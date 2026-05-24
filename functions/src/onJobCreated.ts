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

import {
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const onJobCreated = onDocumentCreated(
  "printJobs/{jobId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("onJobCreated: No data in event");
      return;
    }

    const jobId = event.params.jobId;
    const data = snapshot.data();
    const shopId = data.shopId as string;
    const fileName = data.fileName as string;
    const copies = data.copies as number || 1;

    logger.info(`New job created: ${jobId} for shop ${shopId}`);

    const db = admin.firestore();

    // 1. Set expiresAt (24 hours from now)
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 24 * 60 * 60 * 1000)
    );

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

      const shopData = shopDoc.data()!;
      const fcmToken = shopData.fcmToken as string | undefined;
      const shopName = shopData.name as string;

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
      } else {
        logger.warn(`Shop ${shopId} has no FCM token`);
      }
    } catch (error) {
      logger.error("Error sending FCM to shop:", error);
    }

    // 3. Increment shop active jobs counter
    try {
      await db.doc(`shops/${shopId}`).update({
        "stats.activeJobs": admin.firestore.FieldValue.increment(1),
      });
    } catch (error) {
      logger.error("Error updating shop stats:", error);
    }
  }
);
