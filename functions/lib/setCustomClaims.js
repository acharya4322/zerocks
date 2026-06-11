"use strict";
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
exports.setCustomClaims = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const logger = __importStar(require("firebase-functions/logger"));
const VALID_ROLES = ["superadmin", "admin", "shop_owner", "customer"];
exports.setCustomClaims = (0, https_1.onCall)({ maxInstances: 10 }, async (request) => {
    // 1. Verify authentication
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Must be logged in.");
    }
    // 2. Verify caller is superadmin
    const callerRole = request.auth.token.role;
    if (callerRole !== "superadmin") {
        throw new https_1.HttpsError("permission-denied", "Only superadmins can manage roles.");
    }
    // 3. Validate input
    const { targetUid, role } = request.data;
    if (!targetUid || typeof targetUid !== "string") {
        throw new https_1.HttpsError("invalid-argument", "targetUid is required.");
    }
    if (!role || !VALID_ROLES.includes(role)) {
        throw new https_1.HttpsError("invalid-argument", `Invalid role. Must be one of: ${VALID_ROLES.join(", ")}`);
    }
    // 4. Safety check: don't demote another superadmin
    if (role !== "superadmin") {
        const targetUser = await admin.auth().getUser(targetUid);
        const targetRole = targetUser.customClaims?.role;
        if (targetRole === "superadmin" && targetUid !== request.auth.uid) {
            throw new https_1.HttpsError("permission-denied", "Cannot demote another superadmin.");
        }
    }
    // 5. Set custom claims
    await admin.auth().setCustomUserClaims(targetUid, { role });
    logger.info(`Role set: ${targetUid} → ${role} (by ${request.auth.uid})`);
    // 6. Also update the role in the admin collection if admin role
    if (role === "admin" || role === "superadmin") {
        const db = admin.firestore();
        await db.doc(`admin/${targetUid}`).set({
            email: (await admin.auth().getUser(targetUid)).email || "",
            role,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }
    return { success: true, role };
});
//# sourceMappingURL=setCustomClaims.js.map