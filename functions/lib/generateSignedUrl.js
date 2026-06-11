"use strict";
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
exports.generateSignedUrl = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const logger = __importStar(require("firebase-functions/logger"));
exports.generateSignedUrl = (0, https_1.onCall)({ maxInstances: 50 }, async (request) => {
    // 1. Verify authentication
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "You must be logged in to access files.");
    }
    const { jobId } = request.data;
    if (!jobId || typeof jobId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "jobId is required and must be a string.");
    }
    const db = admin.firestore();
    const callerUid = request.auth.uid;
    // 2. Get the job document
    const jobDoc = await db.doc(`printJobs/${jobId}`).get();
    if (!jobDoc.exists) {
        throw new https_1.HttpsError("not-found", "Print job not found.");
    }
    const jobData = jobDoc.data();
    const shopId = jobData.shopId;
    // 3. Verify the caller owns the shop for this job
    const shopDoc = await db.doc(`shops/${shopId}`).get();
    if (!shopDoc.exists) {
        throw new https_1.HttpsError("not-found", "Shop not found.");
    }
    const shopOwnerId = shopDoc.data().ownerId;
    if (shopOwnerId !== callerUid) {
        // Also allow admins
        const callerRole = request.auth.token.role;
        if (callerRole !== "admin" && callerRole !== "superadmin") {
            throw new https_1.HttpsError("permission-denied", "You don't have access to this job's files.");
        }
    }
    // 4. Find the file in Storage
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({
        prefix: `printJobs/${jobId}/`,
    });
    if (files.length === 0) {
        throw new https_1.HttpsError("not-found", "File not found. It may have been deleted.");
    }
    // 5. Generate signed URL (15-minute expiry)
    const file = files[0];
    const [url] = await file.getSignedUrl({
        action: "read",
        expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    });
    logger.info(`Signed URL generated for job ${jobId} by ${callerUid}`);
    return { url };
});
//# sourceMappingURL=generateSignedUrl.js.map