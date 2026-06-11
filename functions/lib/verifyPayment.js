"use strict";
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
exports.verifyPayment = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const db = admin.firestore();
exports.verifyPayment = functions.https.onCall(async (request) => {
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in to verify payment.");
    }
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature, customOrderId } = request.data;
    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature || !customOrderId) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required payment verification parameters.");
    }
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!keySecret) {
        console.error("Razorpay secret not configured in environment variables.");
        throw new functions.https.HttpsError("internal", "Payment gateway configuration error.");
    }
    // Verify signature
    const body = razorpayOrderId + "|" + razorpayPaymentId;
    const expectedSignature = crypto
        .createHmac("sha256", keySecret)
        .update(body.toString())
        .digest("hex");
    if (expectedSignature !== razorpaySignature) {
        console.error("Invalid payment signature detected!");
        throw new functions.https.HttpsError("permission-denied", "Payment verification failed.");
    }
    // Signature is valid. Update payment status in Firestore.
    try {
        // Assuming customOrderId is the payment document ID, or we fetch the payment record
        // Here we'll update the order document directly
        await db.collection("orders").doc(customOrderId).update({
            status: "paid",
            paymentId: razorpayPaymentId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error("Error updating order status:", error);
        throw new functions.https.HttpsError("internal", "Failed to update order status.");
    }
});
//# sourceMappingURL=verifyPayment.js.map