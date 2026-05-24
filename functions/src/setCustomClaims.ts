/**
 * setCustomClaims — HTTPS Callable Function
 *
 * Manages role-based access control via Firebase Auth custom claims.
 *
 * Roles: 'superadmin', 'admin', 'shop_owner', 'customer'
 *
 * Security:
 * - Only users with 'superadmin' role can call this function
 * - Cannot demote another superadmin (safety check)
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const VALID_ROLES = ["superadmin", "admin", "shop_owner", "customer"];

export const setCustomClaims = onCall(
  { maxInstances: 10 },
  async (request) => {
    // 1. Verify authentication
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Must be logged in."
      );
    }

    // 2. Verify caller is superadmin
    const callerRole = request.auth.token.role as string | undefined;
    if (callerRole !== "superadmin") {
      throw new HttpsError(
        "permission-denied",
        "Only superadmins can manage roles."
      );
    }

    // 3. Validate input
    const { targetUid, role } = request.data;

    if (!targetUid || typeof targetUid !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "targetUid is required."
      );
    }

    if (!role || !VALID_ROLES.includes(role)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid role. Must be one of: ${VALID_ROLES.join(", ")}`
      );
    }

    // 4. Safety check: don't demote another superadmin
    if (role !== "superadmin") {
      const targetUser = await admin.auth().getUser(targetUid);
      const targetRole = targetUser.customClaims?.role as
        | string
        | undefined;
      if (targetRole === "superadmin" && targetUid !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "Cannot demote another superadmin."
        );
      }
    }

    // 5. Set custom claims
    await admin.auth().setCustomUserClaims(targetUid, { role });

    logger.info(
      `Role set: ${targetUid} → ${role} (by ${request.auth.uid})`
    );

    // 6. Also update the role in the admin collection if admin role
    if (role === "admin" || role === "superadmin") {
      const db = admin.firestore();
      await db.doc(`admin/${targetUid}`).set(
        {
          email: (await admin.auth().getUser(targetUid)).email || "",
          role,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    return { success: true, role };
  }
);
