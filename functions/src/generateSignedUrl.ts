/**
 * generateSignedUrl — HTTPS Callable Function
 *
 * Generates a temporary signed URL for a print job's file.
 * URL expires after 15 minutes.
 *
 * Security:
 * - Caller must be authenticated
 * - Caller must own the shop associated with the job
 * - Job must have a valid file in Storage
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const generateSignedUrl = onCall(
  { maxInstances: 50 },
  async (request) => {
    // 1. Verify authentication
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to access files."
      );
    }

    const { jobId } = request.data;
    if (!jobId || typeof jobId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "jobId is required and must be a string."
      );
    }

    const db = admin.firestore();
    const callerUid = request.auth.uid;

    // 2. Get the job document
    const jobDoc = await db.doc(`printJobs/${jobId}`).get();
    if (!jobDoc.exists) {
      throw new HttpsError("not-found", "Print job not found.");
    }

    const jobData = jobDoc.data()!;
    const shopId = jobData.shopId as string;

    // 3. Verify the caller owns the shop for this job
    const shopDoc = await db.doc(`shops/${shopId}`).get();
    if (!shopDoc.exists) {
      throw new HttpsError("not-found", "Shop not found.");
    }

    const shopOwnerId = shopDoc.data()!.ownerId as string;
    if (shopOwnerId !== callerUid) {
      // Also allow admins
      const callerRole = request.auth.token.role as string | undefined;
      if (callerRole !== "admin" && callerRole !== "superadmin") {
        throw new HttpsError(
          "permission-denied",
          "You don't have access to this job's files."
        );
      }
    }

    // 4. Find the file in Storage
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({
      prefix: `printJobs/${jobId}/`,
    });

    if (files.length === 0) {
      throw new HttpsError(
        "not-found",
        "File not found. It may have been deleted."
      );
    }

    // 5. Generate signed URL (15-minute expiry)
    const file = files[0];
    const [url] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    });

    logger.info(
      `Signed URL generated for job ${jobId} by ${callerUid}`
    );

    return { url };
  }
);
