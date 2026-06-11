/**
 * Zerocks Cloud Functions — Barrel Export
 *
 * All Cloud Functions are exported from this file.
 * Firebase Functions v5 (2nd gen) with modular syntax.
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK (once, before any function imports)
admin.initializeApp();

// Export all functions
export { onJobCreated } from "./onJobCreated";
export { onJobStatusChanged as onJobCompleted } from "./onJobCompleted";
export { generateSignedUrl } from "./generateSignedUrl";
export { cleanupExpiredJobs as cleanupExpired } from "./cleanupExpired";
export { setCustomClaims } from "./setCustomClaims";
export { createRazorpayOrder } from "./createRazorpayOrder";
export { verifyPayment } from "./verifyPayment";
