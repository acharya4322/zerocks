import * as functions from "firebase-functions/v2";
import Razorpay from "razorpay";


export const createRazorpayOrder = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be logged in to create an order."
    );
  }

  const { amountInPaise, orderId } = request.data;

  if (!amountInPaise || amountInPaise <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid amount provided."
    );
  }

  // Get keys from environment variables
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !keySecret) {
    console.error("Razorpay keys not configured in environment variables.");
    throw new functions.https.HttpsError(
      "internal",
      "Payment gateway configuration error."
    );
  }

  const razorpay = new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });

  try {
    const options = {
      amount: amountInPaise,
      currency: "INR",
      receipt: orderId,
    };

    const order = await razorpay.orders.create(options);

    return {
      id: order.id,
      amount: order.amount,
      currency: order.currency,
    };
  } catch (error) {
    console.error("Error creating Razorpay order:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to create payment order."
    );
  }
});
