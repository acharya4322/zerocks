import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

const db = admin.firestore();

export const verifyPayment = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be logged in to verify payment."
    );
  }

  const { razorpayOrderId, razorpayPaymentId, razorpaySignature, customOrderId } = request.data;

  if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature || !customOrderId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required payment verification parameters."
    );
  }

  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keySecret) {
    console.error("Razorpay secret not configured in environment variables.");
    throw new functions.https.HttpsError(
      "internal",
      "Payment gateway configuration error."
    );
  }

  // Verify signature
  const body = razorpayOrderId + "|" + razorpayPaymentId;
  const expectedSignature = crypto
    .createHmac("sha256", keySecret)
    .update(body.toString())
    .digest("hex");

  if (expectedSignature !== razorpaySignature) {
    console.error("Invalid payment signature detected!");
    throw new functions.https.HttpsError(
      "permission-denied",
      "Payment verification failed."
    );
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
  } catch (error) {
    console.error("Error updating order status:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to update order status."
    );
  }
});
