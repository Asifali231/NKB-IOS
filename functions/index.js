const admin = require("firebase-admin");
const cors = require("cors")({origin: true});
const crypto = require("crypto");
const axios = require("axios");
const nodemailer = require("nodemailer");
const querystring = require("querystring");
const {sendMail} = require("./emailService");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();

const SMTP_USER = defineSecret("SMTP_USER");
const SMTP_PASSWORD = defineSecret("SMTP_PASSWORD");
const REVENUECAT_API_KEY = defineSecret("REVENUECAT_API_KEY");
const REVENUECAT_WEBHOOK_AUTHORIZATION =
  defineSecret("REVENUECAT_WEBHOOK_AUTHORIZATION");

const WEB_PROJECT_ID = "nikah-blessing";
const webApp =
  admin.apps.find((app) => app.name === "web") ||
  admin.initializeApp(
      {
        credential: admin.credential.applicationDefault(),
        projectId: WEB_PROJECT_ID,
      },
      "web",
  );

const MERCHANT_ID = process.env.JAZZCASH_MERCHANT_ID;
const PASSWORD = process.env.JAZZCASH_PASSWORD;
const INTEGRITY_SALT = process.env.JAZZCASH_INTEGRITY_SALT;
const BASE_URL = "https://onlinepayments.jazzcash.com.pk/payment-orchestrator/api/v2/rest/payments/m-wallet";

const transporter = nodemailer.createTransport({
  host: "smtp.titan.email",
  port: 465,
  secure: true, // true for port 465, false for port 587
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

async function sendPushToToken(token, title, body, imageUrl = "", type = "general") {
  const normalizedToken = String(token || "").trim();
  if (!normalizedToken) return null;
  const image = /^https?:\/\//i.test(String(imageUrl || "").trim()) ?
    String(imageUrl).trim() : "";

  const message = {
    token: normalizedToken,
    notification: {
      title: String(title || "Nikah Blessing"),
      body: String(body || ""),
      ...(image ? {imageUrl: image} : {}),
    },
    data: {type: String(type)},
    android: {
      priority: "high",
      notification: {
        sound: "default",
        priority: "high",
        channelId: "high_importance_channel",
        ...(image ? {imageUrl: image} : {}),
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: String(title || "Nikah Blessing"),
            body: String(body || ""),
          },
          sound: "default",
        },
      },
      ...(image ? {fcmOptions: {imageUrl: image}} : {}),
    },
  };

  try {
    return await admin.messaging().send(message);
  } catch (error) {
    console.error("Push notification delivery failed:", {
      code: error?.code,
      message: error?.message,
      type,
    });
    return null;
  }
}

async function sendPushToUser(
    userId,
    title,
    body,
    type = "general",
    firestoreDb = admin.firestore(),
    imageUrl = "",
) {
  if (!userId) return null;
  try {
    const userSnapshot = await firestoreDb.collection("users").doc(userId).get();
    const userData = userSnapshot.data() || {};
    return await sendPushToToken(
        userData.fcmToken || userData.userDeviceToken,
        title,
        body,
        imageUrl,
        type,
    );
  } catch (error) {
    console.error("Unable to load recipient for push notification:", {
      userId,
      code: error?.code,
      message: error?.message,
      type,
    });
    return null;
  }
}

function parseJazzCashPostBody(req) {
  const body = req.body;

  if (body && typeof body === "object" && !Buffer.isBuffer(body)) {
    const keys = Object.keys(body);
    if (keys.length > 0 && (body.pp_ResponseCode !== undefined || body.pp_TxnRefNo !== undefined)) {
      return body;
    }
  }

  const raw =
    req.rawBody?.toString("utf8") || (typeof body === "string" ? body : "");

  if (raw && raw.trim()) {
    return querystring.parse(raw);
  }

  return typeof body === "object" && body !== null ? body : {};
}
function normalizePackageToken(value) {
  return String(value || "").replace(/[^a-zA-Z0-9]/g, "").toLowerCase();
}
async function resolvePackageFromIdentifier(firestoreDb, identifier) {
  const raw = String(identifier || "").trim();
  if (!raw) return null;

  const packagesCol = firestoreDb.collection("packages");

  const byId = await packagesCol.doc(raw).get();
  if (byId.exists) {
    return {id: byId.id, data: byId.data()};
  }

  let snap = await packagesCol.where("name", "==", raw).limit(1).get();
  if (!snap.empty) {
    const doc = snap.docs[0];
    return {id: doc.id, data: doc.data()};
  }

  const target = normalizePackageToken(raw);
  if (!target) return null;

  snap = await packagesCol.get();
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const name = data.name || "";
    if (normalizePackageToken(name) === target) {
      return {id: doc.id, data};
    }
  }

  return null;
}
async function getExistingWebPayment(txnRefNo) {
  const webDb = webApp.firestore();
  const defaultDb = admin.firestore();

  if (!txnRefNo) {
    return {
      webDb,
      webPaymentRef: null,
      existingPayment: {},
    };
  }

  const webPaymentRef = webDb.collection("payments").doc(txnRefNo);
  const webSnap = await webPaymentRef.get();
  if (webSnap.exists) {
    return {
      webDb,
      webPaymentRef,
      existingPayment: webSnap.data(),
    };
  }

  const defaultSnap = await defaultDb.collection("payments").doc(txnRefNo).get();
  return {
    webDb,
    webPaymentRef,
    existingPayment: defaultSnap.exists ? defaultSnap.data() : {},
  };
}
function assertJazzCashConfiguration() {
  const missing = [
    ["JAZZCASH_MERCHANT_ID", MERCHANT_ID],
    ["JAZZCASH_PASSWORD", PASSWORD],
    ["JAZZCASH_INTEGRITY_SALT", INTEGRITY_SALT],
  ]
      .filter(([, value]) => !value)
      .map(([name]) => name);

  if (missing.length > 0) {
    throw new Error(
        `Missing required payment configuration: ${missing.join(", ")}`,
    );
  }
}

function generateHash(data) {
  assertJazzCashConfiguration();
  const sortedKeys = Object.keys(data).sort();
  let hashString = INTEGRITY_SALT;

  for (const key of sortedKeys) {
    if (key.startsWith("pp")) {
      hashString += `&${data[key]}`;
    }
  }

  return crypto
      .createHmac("sha256", INTEGRITY_SALT)
      .update(hashString)
      .digest("hex")
      .toUpperCase();
}
const jazzCashWebReturnHandler = async (req, res) => {
  try {
    const paymentResponse = parseJazzCashPostBody(req);
    console.log("JazzCash Payment Response (Web):", paymentResponse);

    const {
      pp_ResponseCode,
      pp_TxnRefNo,
      pp_Amount,
      pp_TxnCurrency,
      ppmpf_1: uidFromGateway,
      ppmpf_2: pkgIdentifierFromGateway,
      ppmpf_3: chatCreditsStr,
      ppmpf_4: proposalsStr,
      ppmpf_5: source,
    } = paymentResponse;

    if (!pp_TxnRefNo) {
      throw new Error("Missing transaction reference number");
    }

    const {webDb, webPaymentRef, existingPayment} = await getExistingWebPayment(pp_TxnRefNo);

    const uid = String(uidFromGateway || existingPayment.userId || "").trim();
    const pkgIdentifier = String(
        pkgIdentifierFromGateway ||
      existingPayment.packageDocumentId ||
      existingPayment.packageSubscribed ||
      "",
    ).trim();

    const success = String(pp_ResponseCode || "").trim() === "000";

    if (success) {
      console.log(`Payment Successful: ${pp_TxnRefNo}`);

      if (!uid) {
        throw new Error(`User not found for transaction "${pp_TxnRefNo}"`);
      }

      const resolvedPackage = await resolvePackageFromIdentifier(webDb, pkgIdentifier);
      if (!resolvedPackage) {
        throw new Error(`Package not found for identifier "${pkgIdentifier}"`);
      }

      const packageData = resolvedPackage.data;
      const packageId = resolvedPackage.id;

      const chatCredits = parseInt(chatCreditsStr, 10) || packageData.chatCredits || 5;
      const proposalLimit = parseInt(proposalsStr, 10) || packageData.proposalLimit || 5;

      const validityDays = parseInt(packageData.validity, 10) || 0;
      const now = new Date();
      const expiryDate = new Date(now);
      expiryDate.setDate(now.getDate() + validityDays);

      const userRef = webDb.collection("users").doc(uid);
      await userRef.update({
        packageSubscribed: packageId,
        numberOfProposals: proposalLimit,
        numberOfChatCredits: chatCredits,
        packageExpiry: admin.firestore.Timestamp.fromDate(expiryDate),
        isVerified: "Verified",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};
      await sendPushToUser(
          uid,
          "Payment Successful",
          `Your payment for the ${packageData.name || pkgIdentifier} package was successful.`,
          "payment_success",
          webDb,
      );

      if (userData.email) {
        await sendMail("payment_verified", userData.email, {
          userName: userData.name || userData.fullName || "User",
          packageName: packageData.name || pkgIdentifier,
          finalAmount: (Number(pp_Amount || 0) / 100).toFixed(2),
          transactionId: pp_TxnRefNo,
        });
      }

      await webPaymentRef.set(
          {
            userId: uid,
            userEmail: userData.email || null,
            userPhone: userData.phone || null,
            userDisplayName: userData.name || userData.fullName || null,
            packageSubscribed: packageData.name || pkgIdentifier,
            packageDocumentId: packageId,
            finalAmount: Number(pp_Amount || 0) / 100,
            transactionId: pp_TxnRefNo,
            status: "verified",
            onlinePaymentStage: "completed",
            packageApplied: true,
            packageUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            gatewayCompletedAt: admin.firestore.FieldValue.serverTimestamp(),
            modeOfPayment: "jazzcash",
            channel: "online",
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
            currency: pp_TxnCurrency,
            paymentType: "JazzCash",
            source: String(source || "web").trim().toLowerCase(),
            chatCreditsAssigned: chatCredits,
            proposalsAssigned: proposalLimit,
            response: paymentResponse,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
      );

      return res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Successful</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .success { color: green; }
          </style>
        </head>
        <body>
          <h1 class="success">Payment Successful</h1>
          <p>Your payment of ${(Number(pp_Amount || 0) / 100).toFixed(2)} ${pp_TxnCurrency} has been processed.</p>
          <p>Transaction Ref #: <strong>${pp_TxnRefNo}</strong></p>
        </body>
        </html>
      `);
    }

    console.error(`Payment Failed: ${pp_TxnRefNo}`);

    const userSnap = uid ? await webDb.collection("users").doc(uid).get() : null;
    const userData = userSnap && userSnap.exists ? userSnap.data() : {};
    await sendPushToUser(
        uid,
        "Payment Failed",
        `Your payment could not be completed. ${paymentResponse.pp_ResponseMessage || "Please try again."}`,
        "payment_failed",
        webDb,
    );

    if (userData.email) {
      await sendMail("payment_rejected", userData.email, {
        userName: userData.name || userData.fullName || "User",
        packageName: pkgIdentifier,
        transactionId: pp_TxnRefNo,
        reason: paymentResponse.pp_ResponseMessage || "Payment failed",
      });
    }

    await webPaymentRef.set(
        {
          userId: uid || null,
          userEmail: userData.email || null,
          userPhone: userData.phone || null,
          userDisplayName: userData.name || userData.fullName || null,
          packageSubscribed: pkgIdentifier || null,
          packageDocumentId: existingPayment.packageDocumentId || null,
          finalAmount: Number(pp_Amount || 0) / 100,
          transactionId: pp_TxnRefNo,
          status: "rejected",
          onlinePaymentStage: "failed",
          modeOfPayment: "jazzcash",
          channel: "online",
          rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          currency: pp_TxnCurrency,
          paymentType: "JazzCash",
          source: String(source || "web").trim().toLowerCase(),
          response: paymentResponse,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
    );

    return res.status(400).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Failed</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .error { color: red; }
          .details { background-color: #f8d7da; padding: 20px; border: 1px solid #f5c2c7; border-radius: 5px; color: #842029; }
        </style>
      </head>
      <body>
        <h1 class="error">Payment Failed</h1>
        <p>Transaction Ref #: <strong>${pp_TxnRefNo || "N/A"}</strong></p>
        <div class="details">
          <p><strong>Response Code:</strong> ${pp_ResponseCode || "Unknown"}</p>
          <p><strong>Message:</strong> ${paymentResponse.pp_ResponseMessage || "No details available"}</p>
        </div>
      </body>
      </html>
    `);
  } catch (error) {
    console.error("Error processing payment (Web):", error);

    try {
      const paymentResponse = parseJazzCashPostBody(req);
      const txnId = paymentResponse.pp_TxnRefNo;
      const errUid = paymentResponse.ppmpf_1;
      const {webDb, webPaymentRef, existingPayment} = await getExistingWebPayment(txnId);
      const effectiveUid = String(errUid || existingPayment.userId || "").trim();

      if (txnId && effectiveUid && webPaymentRef) {
        const userSnap = await webDb.collection("users").doc(effectiveUid).get();
        const userData = userSnap.data() || {};

        await webPaymentRef.set(
            {
              userId: effectiveUid,
              userEmail: userData.email || null,
              userPhone: userData.phone || null,
              userDisplayName: userData.name || userData.fullName || null,
              transactionId: txnId,
              status: "unclear",
              onlinePaymentStage: "unclear",
              processingError: error.message || String(error),
              modeOfPayment: "jazzcash",
              channel: "online",
              paymentType: "JazzCash",
              source: "web",
              lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              response: paymentResponse,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true},
        );
      }
    } catch (persistErr) {
      console.error("Could not persist unclear web payment record:", persistErr);
    }

    return res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Server Error</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .error { color: red; }
          .details { background-color: #f8d7da; padding: 20px; border: 1px solid #f5c2c7; border-radius: 5px; color: #842029; }
        </style>
      </head>
      <body>
        <h1 class="error">Server Error</h1>
        <div class="details">
          <p><strong>Error Message:</strong> ${error.message || "Internal Server Error"}</p>
        </div>
      </body>
      </html>
    `);
  }
};
async function sendTransactionEmail({email, name, amount, txnRefNo, status}) {
  try {
    const info = await transporter.sendMail({
      from: "contact@nikahblessing.com",
      to: email,
      subject: `Payment ${status}`,
      html: `
        <h2>Dear ${name || "User"},</h2>
        <p>Your payment transaction has been <strong>${status}</strong>.</p>
        <p><strong>Transaction Reference:</strong> ${txnRefNo}</p>
        <p><strong>Amount:</strong> PKR ${(Number(amount || 0) / 100).toFixed(2)}</p>
        <p>Thank you for using our service!</p>
      `,
    });
    console.log("Email sent:", info.messageId);
  } catch (err) {
    console.error("Email sending error:", err);
  }
}
async function updateUserPackage(uid, pkgName) {
  try {
    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();
    const pkgRef = db.collection("packages").doc(pkgName);
    const pkgSnap = await pkgRef.get();

    if (!userSnap.exists || !pkgSnap.exists) return false;

    const userData = userSnap.data();
    const pkgData = pkgSnap.data();

    const today = new Date();
    const futureDate = new Date(today.getTime() + (pkgData.days * 24 * 60 * 60 * 1000));

    await userRef.update({
      PackageSubscribed: pkgData.name,
      ChatCredit: (userData.ChatCredit || 0) + pkgData.ChatCredit,
      DailyProfiles: (userData.DailyProfiles || 0) + pkgData.DailyProfiles,
      PackageExpiry: futureDate.toISOString(),
      iosSubscription: admin.firestore.FieldValue.delete(),
    });

    await db
        .collection("proposals")
        .doc(userData.JobCountry)
        .collection(userData.Gender)
        .doc(userData.uid)
        .update({
          PackageSubscribed: pkgData.name,
          ChatCredit: (userData.ChatCredit || 0) + pkgData.ChatCredit,
          DailyProfiles: (userData.DailyProfiles || 0) + pkgData.DailyProfiles,
          PackageExpiry: futureDate.toISOString(),
          iosSubscription: admin.firestore.FieldValue.delete(),
        });

    await sendPushToUser(
        uid,
        "Package Approved",
        `Your ${pkgData.name || pkgName} package was successfully activated.`,
        "payment_success",
    );

    await sendTransactionEmail({
      email: userData.email,
      name: userData.fullName,
      amount: pkgData.price * 100,
      txnRefNo: "Package Upgrade",
      status: "Successful",
    });

    console.log("Package Subscribed");
    return true;
  } catch (error) {
    console.error("Error updating user package:", error);
    return false;
  }
}


exports.initiateJazzCashPayment = onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const {mobileNumber, cnic, amount, description, uid, pkgName} = req.body;

      const now = new Date(Date.now() + 5 * 60 * 60 * 1000); // UTC+5
      const txnDateTime = now.toISOString().replace(/[-:.TZ]/g, "").substring(0, 14);
      const expiryDateTime = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString().replace(/[-:.TZ]/g, "").substring(0, 14);
      const txnRefNo = `TXN${Date.now()}`;
      const billRef = `billRef${Date.now()}`;

      const requestData = {
        pp_Amount: `${amount * 100}`,
        pp_BillReference: billRef,
        pp_Description: description,
        pp_Language: "EN",
        pp_MerchantID: MERCHANT_ID,
        pp_Password: PASSWORD,
        pp_TxnCurrency: "PKR",
        pp_TxnDateTime: txnDateTime,
        pp_TxnExpiryDateTime: expiryDateTime,
        pp_TxnRefNo: txnRefNo,
        pp_CNIC: cnic,
        pp_MobileNumber: mobileNumber,
        ppmpf_1: uid,
        ppmpf_2: pkgName,
      };

      requestData.pp_SecureHash = generateHash(requestData);

      const response = await axios.post(BASE_URL, requestData, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (response.data.pp_ResponseCode === "000") {
        await updateUserPackage(uid, pkgName);
        const userSnap = await admin.firestore().collection("users").doc(uid).get();
        const userData = userSnap.data();
        await sendTransactionEmail({
          email: userData.email,
          name: userData.fullName,
          amount: amount * 100,
          txnRefNo,
          status: "Successful",
        });
      } else {
        const userSnap = await admin.firestore().collection("users").doc(uid).get();
        const userData = userSnap.data();
        await sendTransactionEmail({
          email: userData.email,
          name: userData.fullName,
          amount: amount * 100,
          txnRefNo,
          status: "Failed",
        });
      }

      res.status(200).json(response.data);
    } catch (err) {
      console.error("JazzCash Error:", err);
      res.status(500).json({error: err.message});
    }
  });
});
exports.jazzCashWebReturnUrl = onRequest(jazzCashWebReturnHandler);
exports.jazzCashReturnUrl = onRequest(async (req, res) => {
  try {
    const paymentResponse = req.body;
    console.log("JazzCash Payment Response:", paymentResponse);

    const {
      pp_ResponseCode,
      pp_TxnRefNo,
      pp_Amount,
      pp_TxnCurrency,
      ppmpf_1,
      ppmpf_2,
      ppmpf_5,
    } = paymentResponse;

    const uid = ppmpf_1;
    const pkgName = ppmpf_2;

    // If from web, handle with web handler (no proxy, direct internal call)
    if (ppmpf_5 === "web") {
      return jazzCashWebReturnHandler(req, res);
    }

    // ✅ If Payment was Successful (non-web/mobile, uses default admin)
    if (pp_ResponseCode === "000") {
      console.log(`Payment Successful: ${pp_TxnRefNo}`);

      // Update user's package
      await updateUserPackage(uid, pkgName);

      // Get user data
      const userSnap = await admin.firestore().collection("users").doc(uid).get();
      const userData = userSnap.data();

      // Send success email
      await sendTransactionEmail({
        email: userData.email,
        name: userData.fullName,
        amount: pp_Amount,
        txnRefNo: pp_TxnRefNo,
        status: "Successful",
      });

      // Save the payment
      await admin.firestore().collection("payments").doc(pp_TxnRefNo).set({
        amount: pp_Amount,
        currency: pp_TxnCurrency,
        status: "SUCCESS",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Example: If you need to use Storage in default project (e.g., upload a receipt image)
      // const defaultStorage = admin.storage().bucket('your-default-storage-bucket'); // Replace with actual
      // const file = defaultStorage.file(`receipts/${pp_TxnRefNo}.pdf`);
      // await file.save(Buffer.from('Receipt content')); // Example upload

      return res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Successful</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .success { color: green; }
          </style>
        </head>
        <body>
          <h1 class="success">Payment Successful</h1>
          <p>Your payment of ${(pp_Amount / 100).toFixed(2)} ${pp_TxnCurrency} has been processed.</p>
          <p>Transaction Ref #: <strong>${pp_TxnRefNo}</strong></p>
        </body>
        </html>
      `);
    } else {
      // ❌ Payment Failed
      console.error(`Payment Failed: ${pp_TxnRefNo}`);

      const userSnap = await admin.firestore().collection("users").doc(uid).get();
      const userData = userSnap.data();
      await sendPushToUser(
          uid,
          "Payment Failed",
          "Your payment could not be completed. Please try again.",
          "payment_failed",
      );

      await sendTransactionEmail({
        email: userData.email,
        name: userData.fullName,
        amount: pp_Amount,
        txnRefNo: pp_TxnRefNo,
        status: "Failed",
      });

      await admin.firestore().collection("payments").doc(pp_TxnRefNo).set({
        amount: pp_Amount,
        currency: pp_TxnCurrency,
        status: "FAILED",
        error: paymentResponse,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(400).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Failed</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .error { color: red; }
            .details { background-color: #f8d7da; padding: 20px; border: 1px solid #f5c2c7; border-radius: 5px; color: #842029; }
          </style>
        </head>
        <body>
          <h1 class="error">Payment Failed</h1>
          <p>Transaction Ref #: <strong>${pp_TxnRefNo || "N/A"}</strong></p>
          <div class="details">
            <p><strong>Response Code:</strong> ${pp_ResponseCode || "Unknown"}</p>
            <p><strong>Message:</strong> ${paymentResponse.pp_ResponseMessage || "No details available"}</p>
          </div>
        </body>
        </html>
      `);
    }
  } catch (error) {
    console.error("Error processing payment:", error);

    return res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Server Error</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .error { color: red; }
          .details { background-color: #f8d7da; padding: 20px; border: 1px solid #f5c2c7; border-radius: 5px; color: #842029; }
        </style>
      </head>
      <body>
        <h1 class="error">Server Error</h1>
        <div class="details">
          <p><strong>Error Message:</strong> ${error.message || "Internal Server Error"}</p>
        </div>
      </body>
      </html>
    `);
  }
});
exports.sendNotification = onCall(async (request) => {
  const data = request.data;
  try {
    const payload = data?.data && typeof data.data === "object" ? data.data : data || {};
    const uid = String(payload.uid || "").trim();
    if (!uid) {
      throw new HttpsError(
          "invalid-argument",
          "A notification recipient is required.",
      );
    }

    const messageId = await sendPushToUser(
        uid,
        payload.title,
        payload.body,
        payload.type || "general",
        admin.firestore(),
        payload.imageUrl,
    );
    return {success: Boolean(messageId), response: messageId};
  } catch (error) {
    console.error("Error sending message:", error?.code, error?.message);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Unable to send message.", error);
  }
});
exports.sendBulkNotification = onCall(async (request) => {
  const data = request.data;
  try {
    const payload = data?.data && typeof data.data === "object" ? data.data : data || {};
    const title = String(payload.title || "").trim();
    const body = String(payload.body || "").trim();
    const imageUrl = String(payload.imageUrl || "").trim();
    const filters = payload.filters || {};

    if (!title || !body) {
      throw new HttpsError(
          "invalid-argument",
          "Notification title and body are required.",
      );
    }

    let query = admin.firestore().collection("users");

    if (filters.Country) {
      query = query.where("NationalityCountry", "==", filters.Country);
    }
    if (filters.Gender) {
      query = query.where("Gender", "==", filters.Gender);
    }
    if (filters.Package) {
      query = query.where("PackageSubscribed", "==", filters.Package);
    }
    if (filters.Verification) {
      query = query.where("VerificationStatus", "==", filters.Verification);
    }

    const snapshot = await query.get();
    const matchedUsers = snapshot.size;

    if (matchedUsers === 0) {
      return {
        matchedUsers: 0,
        usersWithTokens: 0,
        successCount: 0,
        failureCount: 0,
      };
    }

    const tokens = [];
    snapshot.docs.forEach((doc) => {
      const userData = doc.data() || {};
      const token = String(userData.fcmToken || userData.userDeviceToken || "").trim();
      if (token) {
        tokens.push(token);
      }
    });

    const uniqueTokens = [...new Set(tokens)];

    if (uniqueTokens.length === 0) {
      return {
        matchedUsers,
        usersWithTokens: 0,
        successCount: 0,
        failureCount: 0,
      };
    }

    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < uniqueTokens.length; i += 500) {
      const batchTokens = uniqueTokens.slice(i, i + 500);
      const message = {
        tokens: batchTokens,
        notification: {
          title,
          body,
          ...(imageUrl ? {imageUrl} : {}),
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            priority: "high",
            channelId: "high_importance_channel",
            ...(imageUrl ? {imageUrl} : {}),
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              sound: "default",
            },
          },
          ...(imageUrl ?
            {
              fcmOptions: {
                imageUrl,
              },
            } :
            {}),
        },
        data: {
          additionalInfo: "bulk_notification",
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      successCount += response.successCount;
      failureCount += response.failureCount;
    }

    return {
      matchedUsers,
      usersWithTokens: uniqueTokens.length,
      successCount,
      failureCount,
    };
  } catch (error) {
    console.error("Error sending bulk notification:", error);
    throw new HttpsError(
        "internal",
        error?.message || "Unable to send bulk notification.",
        {
          originalMessage: error?.message || null,
          code: error?.code || null,
        },
    );
  }
});
exports.handlePaymentStatus = onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log("Received req.body:", req.body);

      const {auth_token, orderRefNum} = req.body;

      console.log("Received auth_token:", auth_token);
      console.log("Received orderRefNum:", orderRefNum);

      // Store payment info in Firestore
      await admin.firestore().collection("payments").doc(orderRefNum).set({
        auth_token,
        status: "PENDING",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Return the final postback URL
      const finalPostbackUrl = `https://${req.hostname}/handleFinalPaymentStatus`;
      res.json({postBackURL: finalPostbackUrl});
    } catch (error) {
      console.error("Error handling payment status:", error);
      res.status(500).json({error: "Internal server error"});
    }
  });
});

exports.handleFinalPaymentStatus = onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      console.log("Received req.body:", req.body);
      const {status, desc, orderRefNumber} = req.body;

      console.log("Received status:", status);
      console.log("Received desc:", desc);

      // Update payment status in Firestore
      await admin.firestore().collection("payments").doc(orderRefNumber).update({
        status: status,
        description: desc,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const paymentSnapshot = await admin.firestore()
          .collection("payments")
          .doc(orderRefNumber)
          .get();
      const payment = paymentSnapshot.data() || {};
      if (String(status).toLowerCase() === "success") {
        const title = "Payment Successful";
        const body = `Your payment of PKR ${payment.amount || 0} has been processed successfully.`;
        if (payment.userId) {
          await sendPushToUser(payment.userId, title, body, "payment_success");
        } else {
          await sendPushToToken(payment.fcmToken, title, body, "", "payment_success");
        }
      } else {
        const title = "Payment Failed";
        const body = "Your payment could not be completed. Please try again.";
        if (payment.userId) {
          await sendPushToUser(payment.userId, title, body, "payment_failed");
        } else {
          await sendPushToToken(payment.fcmToken, title, body, "", "payment_failed");
        }
      }

      res.sendStatus(200);
    } catch (error) {
      console.error("Error handling final payment status:", error);
      res.status(500).json({error: "Internal server error"});
    }
  });
});
exports.initializePayment = onCall(async (request) => {
  const data = request.data;
  try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be logged in");
    }

    const {orderId, amount} = data;

    // Create payment record
    await admin.firestore()
        .collection("payments")
        .doc(orderId)
        .set({
          userId: request.auth.uid,
          amount: amount,
          status: "pending",
          provider: "easypaisa",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

    return {success: true};
  } catch (error) {
    console.error("Error initializing payment:", error);
    throw new HttpsError("internal", "Error initializing payment");
  }
});
exports.jazzCashIPN = onRequest(async (req, res) => {
  try {
    const paymentResponse = req.body;
    console.log("JazzCash Payment Response:", paymentResponse);

    const {pp_ResponseCode, pp_TxnRefNo, pp_Amount, pp_TxnCurrency} = paymentResponse;

    if (pp_ResponseCode === "000") {
      // Payment was successful
      console.log(`Payment Successful: ${pp_TxnRefNo}`);

      // Save the payment record to Firestore
      await admin.firestore().collection("payments").doc(pp_TxnRefNo).set({
        amount: pp_Amount,
        currency: pp_TxnCurrency,
        status: "SUCCESS",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send a styled HTML response for success
      return res.status(200).send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Successful</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            .success { color: green; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1 class="success">Payment Successful</h1>
            <p>Thank you! Your payment of ${(pp_Amount / 100).toFixed(2)} ${pp_TxnCurrency} has been processed successfully.</p>
            <p>Transaction Reference Number: <strong>${pp_TxnRefNo}</strong></p>
          </div>
        </body>
        </html>
      `);
    } else {
      // Payment failed or was canceled
      console.error(`Payment Failed: ${pp_TxnRefNo}`);

      // Save the failed payment record
      await admin.firestore().collection("payments").doc(pp_TxnRefNo).set({
        amount: pp_Amount,
        currency: pp_TxnCurrency,
        status: "FAILED",
        error: paymentResponse,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send a styled HTML response for failure
      return res.status(400).send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Failed</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            .error { color: red; }
            .details { margin-top: 20px; padding: 15px; background-color: #f8d7da; border: 1px solid #f5c2c7; color: #842029; border-radius: 5px; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1 class="error">Payment Failed</h1>
            <p>Unfortunately, your payment could not be processed at this time.</p>
            <p>Transaction Reference Number: <strong>${pp_TxnRefNo || "N/A"}</strong></p>
            <div class="details">
              <h3>Error Details:</h3>
              <p><strong>Response Code:</strong> ${pp_ResponseCode || "Unknown"}</p>
              <p><strong>Error Message:</strong> ${paymentResponse.errorMessage || "No message available"}</p>
            </div>
          </div>
        </body>
        </html>
      `);
    }
  } catch (error) {
    console.error("Error processing payment:", error);

    // Send a styled HTML response for server error
    return res.status(500).send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Server Error</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .container { max-width: 600px; margin: 0 auto; }
          .error { color: red; }
          .details { margin-top: 20px; padding: 15px; background-color: #f8d7da; border: 1px solid #f5c2c7; color: #842029; border-radius: 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1 class="error">Server Error</h1>
          <p>We encountered an error while processing your payment. Please try again later.</p>
          <div class="details">
            <h3>Error Details:</h3>
            <p><strong>Error Code:</strong> 500</p>
            <p><strong>Error Message:</strong> ${error.message || "Internal Server Error"}</p>
          </div>
        </div>
      </body>
      </html>
    `);
  }
});


// -------------------------new-------------------
//
//
//


exports.initiateJazzCashPayment = onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const {mobileNumber, cnic, amount, description, uid, pkgName} = req.body;

      const now = new Date(Date.now() + 5 * 60 * 60 * 1000);
      const txnDateTime = now.toISOString().replace(/[-:.TZ]/g, "").substring(0, 14);
      const expiryDateTime = new Date(now.getTime() + 24 * 60 * 60 * 1000)
          .toISOString()
          .replace(/[-:.TZ]/g, "")
          .substring(0, 14);
      const txnRefNo = `TXN${Date.now()}`;
      const billRef = `billRef${Date.now()}`;

      const requestData = {
        pp_Amount: `${amount * 100}`,
        pp_BillReference: billRef,
        pp_Description: description,
        pp_Language: "EN",
        pp_MerchantID: MERCHANT_ID,
        pp_Password: PASSWORD,
        pp_TxnCurrency: "PKR",
        pp_TxnDateTime: txnDateTime,
        pp_TxnExpiryDateTime: expiryDateTime,
        pp_TxnRefNo: txnRefNo,
        pp_CNIC: cnic,
        pp_MobileNumber: mobileNumber,
        ppmpf_1: uid,
        ppmpf_2: pkgName,
      };

      requestData.pp_SecureHash = generateHash(requestData);

      const response = await axios.post(BASE_URL, requestData, {
        headers: {"Content-Type": "application/json"},
      });

      if (response.data.pp_ResponseCode === "000") {
        await updateUserPackage(uid, pkgName);

        const userSnap = await admin.firestore().collection("users").doc(uid).get();
        const userData = userSnap.data() || {};

        await sendTransactionEmail({
          email: userData.email,
          name: userData.fullName,
          amount: amount * 100,
          txnRefNo,
          status: "Successful",
        });
      } else {
        const userSnap = await admin.firestore().collection("users").doc(uid).get();
        const userData = userSnap.data() || {};

        await sendTransactionEmail({
          email: userData.email,
          name: userData.fullName,
          amount: amount * 100,
          txnRefNo,
          status: "Failed",
        });
      }

      res.status(200).json(response.data);
    } catch (err) {
      console.error("JazzCash Error:", err);
      res.status(500).json({error: err.message});
    }
  });
});
exports.jazzCashWebReturnUrl = onRequest(jazzCashWebReturnHandler);
exports.jazzCashReturnUrl = onRequest(async (req, res) => {
  try {
    const paymentResponse = parseJazzCashPostBody(req);
    console.log("JazzCash Payment Response:", paymentResponse);

    const {
      pp_ResponseCode,
      pp_TxnRefNo,
      pp_Amount,
      pp_TxnCurrency,
      ppmpf_1,
      ppmpf_2,
      ppmpf_5,
    } = paymentResponse;

    const uid = ppmpf_1;
    const pkgName = ppmpf_2;
    const source = String(ppmpf_5 || "").trim().toLowerCase();

    if (source === "web") {
      return jazzCashWebReturnHandler(req, res);
    }

    if (pp_ResponseCode === "000") {
      console.log(`Payment Successful: ${pp_TxnRefNo}`);

      await updateUserPackage(uid, pkgName);

      const userSnap = await admin.firestore().collection("users").doc(uid).get();
      const userData = userSnap.data() || {};

      await sendTransactionEmail({
        email: userData.email,
        name: userData.fullName,
        amount: pp_Amount,
        txnRefNo: pp_TxnRefNo,
        status: "Successful",
      });

      await admin.firestore().collection("payments").doc(pp_TxnRefNo).set(
          {
            amount: pp_Amount,
            currency: pp_TxnCurrency,
            status: "SUCCESS",
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
      );

      return res.status(200).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Payment Successful</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .success { color: green; }
          </style>
        </head>
        <body>
          <h1 class="success">Payment Successful</h1>
          <p>Your payment of ${(Number(pp_Amount || 0) / 100).toFixed(2)} ${pp_TxnCurrency} has been processed.</p>
          <p>Transaction Ref #: <strong>${pp_TxnRefNo}</strong></p>
        </body>
        </html>
      `);
    }

    console.error(`Payment Failed: ${pp_TxnRefNo}`);

    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    const userData = userSnap.data() || {};

    await sendTransactionEmail({
      email: userData.email,
      name: userData.fullName,
      amount: pp_Amount,
      txnRefNo: pp_TxnRefNo,
      status: "Failed",
    });

    await admin.firestore().collection("payments").doc(pp_TxnRefNo).set(
        {
          amount: pp_Amount,
          currency: pp_TxnCurrency,
          status: "FAILED",
          error: paymentResponse,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
    );

    return res.status(400).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Failed</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .error { color: red; }
          .details { background-color: #f8d7da; padding: 20px; border: 1px solid #f5c2c7; border-radius: 5px; color: #842029; }
        </style>
      </head>
      <body>
        <h1 class="error">Payment Failed</h1>
        <p>Transaction Ref #: <strong>${pp_TxnRefNo || "N/A"}</strong></p>
        <div class="details">
          <p><strong>Response Code:</strong> ${pp_ResponseCode || "Unknown"}</p>
          <p><strong>Message:</strong> ${paymentResponse.pp_ResponseMessage || "No details available"}</p>
        </div>
      </body>
      </html>
    `);
  } catch (error) {
    console.error("Error processing payment:", error);

    return res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Server Error</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .error { color: red; }
          .details { background-color: #f8d7da; padding: 20px; border: 1px solid #f5c2c7; border-radius: 5px; color: #842029; }
        </style>
      </head>
      <body>
        <h1 class="error">Server Error</h1>
        <div class="details">
          <p><strong>Error Message:</strong> ${error.message || "Internal Server Error"}</p>
        </div>
      </body>
      </html>
    `);
  }
});

exports.initializeJazzCashPayment = exports.initiateJazzCashPayment;

const IOS_PREMIUM_ENTITLEMENT = "nikah_blessing_pro";

async function getRevenueCatSubscription(userId) {
  const apiKey = REVENUECAT_API_KEY.value();
  if (!apiKey) {
    throw new Error("REVENUECAT_API_KEY is not configured.");
  }

  const response = await axios.get(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
      {
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        timeout: 20000,
      },
  );
  const subscriber = response.data?.subscriber || {};
  const entitlement = subscriber.entitlements?.[IOS_PREMIUM_ENTITLEMENT];
  if (!entitlement) {
    return {isPremium: false};
  }

  const packageSnapshot = await admin.firestore().collection("packages")
      .get();
  const matchingPackages = packageSnapshot.docs.filter((document) => {
    const packageData = document.data();
    return packageData.isActive !== false &&
        String(packageData.ios_product_id || "").trim() ===
        entitlement.product_identifier;
  });
  if (matchingPackages.length !== 1) {
    return {isPremium: false};
  }

  const packageDocument = matchingPackages[0];
  const packageName = String(packageDocument.data().name || "").trim();
  if (!packageName) {
    throw new Error(
        `The iOS package "${packageDocument.id}" has no Firestore display name.`,
    );
  }

  const expiresAt = entitlement.expires_date ?
    Date.parse(entitlement.expires_date) : null;
  const isPremium = expiresAt === null ||
      (Number.isFinite(expiresAt) && expiresAt > Date.now());
  return {
    isPremium,
    productId: entitlement.product_identifier,
    packageDocumentId: packageDocument.id,
    packageName,
  };
}

async function synchronizeIosPremiumPackage(userId, subscription) {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(userId);

  const newlyActivated = await db.runTransaction(async (transaction) => {
    const userSnapshot = await transaction.get(userRef);
    if (!userSnapshot.exists) {
      throw new HttpsError(
          "not-found",
          "The signed-in user profile was not found.",
      );
    }

    const userData = userSnapshot.data() || {};
    const country = String(userData.JobCountry || "").trim();
    const gender = String(userData.Gender || "").trim();
    let proposalRef;
    let proposalSnapshot;

    if (country && gender) {
      proposalRef = db
          .collection("proposals")
          .doc(country)
          .collection(gender)
          .doc(userId);
      proposalSnapshot = await transaction.get(proposalRef);
    }

    const currentSubscription = userData.iosSubscription;
    if (subscription.isPremium) {
      const wasAlreadyActive =
          currentSubscription?.source === "revenuecat" &&
          currentSubscription.productId === subscription.productId;
      const previousPackageName =
          currentSubscription?.source === "revenuecat" ?
            currentSubscription.previousPackageName :
            userData.PackageSubscribed || "Free";
      const proposalData = proposalSnapshot?.exists ?
        proposalSnapshot.data() || {} : {};
      const previousProposalPackageName =
          currentSubscription?.source === "revenuecat" ?
            currentSubscription.previousProposalPackageName :
            proposalData.PackageSubscribed || userData.PackageSubscribed || "Free";

      transaction.update(userRef, {
        PackageSubscribed: subscription.packageName,
        iosSubscription: {
          source: "revenuecat",
          productId: subscription.productId,
          packageDocumentId: subscription.packageDocumentId,
          previousPackageName,
          previousProposalPackageName,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      if (proposalRef && proposalSnapshot.exists) {
        transaction.update(proposalRef, {
          PackageSubscribed: subscription.packageName,
        });
      }
      return !wasAlreadyActive;
    } else if (currentSubscription?.source === "revenuecat") {
      transaction.update(userRef, {
        PackageSubscribed: currentSubscription.previousPackageName || "Free",
        iosSubscription: admin.firestore.FieldValue.delete(),
      });
      if (proposalRef && proposalSnapshot.exists) {
        transaction.update(proposalRef, {
          PackageSubscribed:
              currentSubscription.previousProposalPackageName ||
              currentSubscription.previousPackageName ||
              "Free",
        });
      }
    }
    return false;
  });
  return newlyActivated;
}

async function syncRevenueCatForUser(userId) {
  const subscription = await getRevenueCatSubscription(userId);
  const newlyActivated =
      await synchronizeIosPremiumPackage(userId, subscription);
  if (subscription.isPremium && newlyActivated) {
    await sendPushToUser(
        userId,
        "Payment Successful",
        "Your App Store purchase has been verified and Premium is now active.",
        "payment_success",
    );
  }
  return subscription.isPremium;
}

exports.syncRevenueCatSubscription = onCall(
    {secrets: [REVENUECAT_API_KEY]},
    async (request) => {
      const context = request;
      if (!context.auth) {
        throw new HttpsError(
            "unauthenticated",
            "Sign in before synchronizing a subscription.",
        );
      }

      if (context.auth.uid.startsWith("$RCAnonymousID")) {
        throw new HttpsError(
            "invalid-argument",
            "A Firebase account is required for subscription synchronization.",
        );
      }

      try {
        return {isPremium: await syncRevenueCatForUser(context.auth.uid)};
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("RevenueCat subscription synchronization failed:", error);
        throw new HttpsError(
            "internal",
            "The subscription could not be synchronized. Please try again.",
        );
      }
    },
);

exports.revenueCatWebhook = onRequest(
    {secrets: [REVENUECAT_API_KEY, REVENUECAT_WEBHOOK_AUTHORIZATION]},
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).send("Method not allowed.");
        return;
      }
      const expectedAuthorization =
          REVENUECAT_WEBHOOK_AUTHORIZATION.value();
      if (!expectedAuthorization ||
          req.get("authorization") !== expectedAuthorization) {
        res.status(401).send("Unauthorized.");
        return;
      }

      const userId = req.body?.event?.app_user_id;
      if (typeof userId !== "string" ||
          !userId.trim() ||
          userId.startsWith("$RCAnonymousID")) {
        res.status(400).send("A Firebase app user ID is required.");
        return;
      }

      try {
        await syncRevenueCatForUser(userId);
        res.status(200).send("Subscription synchronized.");
      } catch (error) {
        console.error("RevenueCat webhook synchronization failed:", error);
        res.status(500).send("Subscription synchronization failed.");
      }
    },
);

async function deleteUserAccount(data, context) {
  if (!context.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Sign in before deleting your account.",
    );
  }

  const authTime = Number(context.auth.token.auth_time);
  const now = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(authTime) || now - authTime > 5 * 60 ||
      authTime > now + 60) {
    throw new HttpsError(
        "failed-precondition",
        "Please sign in again before deleting your account.",
    );
  }

  const userId = context.auth.uid;

  try {
    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);
    const userSnapshot = await userRef.get();
    const userData = userSnapshot.data() || {};
    const country = String(userData.JobCountry || "").trim();
    const gender = String(userData.Gender || "").trim();
    const chatSnapshot = await db.collection("Chats")
        .where("users", "array-contains", userId)
        .get();
    const paymentSnapshot = await db.collection("payments")
        .where("userId", "==", userId)
        .get();
    const transactionSnapshot = await db.collection("transactions")
        .where("userId", "==", userId)
        .get();
    const bucket = admin.storage().bucket();
    const fileGroups = await Promise.all([
      bucket.getFiles({prefix: `${userId}/`}),
      bucket.getFiles({prefix: `payment_proofs/${userId}/`}),
    ]);
    const files = [...new Set(fileGroups.flatMap(([group]) => group))];
    const cleanupTasks = [
      db.recursiveDelete(userRef),
      db.collection("notifications").doc(userId).delete(),
      db.collection("fcmTokens").doc(userId).delete(),
      ...chatSnapshot.docs.map((chat) => db.recursiveDelete(chat.ref)),
      ...paymentSnapshot.docs.map((payment) => payment.ref.delete()),
      ...transactionSnapshot.docs.map((transaction) =>
        transaction.ref.delete(),
      ),
      ...files.map((file) => file.delete()),
    ];

    if (admin.app().options.databaseURL) {
      cleanupTasks.push(
          admin.database().ref(`users/${userId}`).remove(),
      );
    } else {
      console.info("Realtime Database is not configured; skipped cleanup.");
    }

    if (country && gender) {
      cleanupTasks.push(
          db.recursiveDelete(
              db.collection("proposals")
                  .doc(country)
                  .collection(gender)
                  .doc(userId),
          ),
      );
    }

    await Promise.all(cleanupTasks);
    await admin.auth().deleteUser(userId);
    return {deleted: true};
  } catch (error) {
    console.error("Account deletion failed:", error);
    throw new HttpsError(
        "internal",
        "Account data could not be fully deleted. Please try again or contact support.",
    );
  }
}

exports.deleteUserAccount = onCall(
    {timeoutSeconds: 540, memory: "1GiB"},
    async (request) => deleteUserAccount(request.data, request),
);

function getEmailOtpDocumentId(email) {
  return crypto.createHash("sha256").update(email).digest("hex");
}

function getEmailOtpHash(email, code) {
  return crypto.createHash("sha256").update(`${email}:${code}`).digest("hex");
}

function getEmailOtpVerificationTokenHash(email, token) {
  return crypto.createHash("sha256").update(`${email}:${token}`).digest("hex");
}

function normalizeOtpEmail(value) {
  const email = String(value || "").trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  return email;
}

exports.requestEmailOtp = onCall(
    {secrets: [SMTP_USER, SMTP_PASSWORD]},
    async (request) => {
      const email = normalizeOtpEmail(request.data?.email);
      const smtpUser = SMTP_USER.value().trim();
      const smtpPassword = SMTP_PASSWORD.value().trim();
      console.info("Email OTP SMTP secret presence:", {
        SMTP_USER: Boolean(smtpUser),
        SMTP_PASSWORD: Boolean(smtpPassword),
      });
      if (!smtpUser || !smtpPassword) {
        throw new HttpsError(
            "failed-precondition",
            "SMTP config missing",
        );
      }

      const db = admin.firestore();
      const challengeRef = db.collection("email_otp_challenges")
          .doc(getEmailOtpDocumentId(email));
      const now = Date.now();
      const code = crypto.randomInt(100000, 1000000).toString();
      await db.runTransaction(async (transaction) => {
        const challenge = await transaction.get(challengeRef);
        const challengeData = challenge.data();
        const sentAt = challengeData?.sentAt;
        if (challengeData?.codeHash &&
            sentAt &&
            now - sentAt.toMillis() < 60000) {
          throw new HttpsError(
              "resource-exhausted",
              "Please wait a minute before requesting another code.",
          );
        }
        transaction.set(challengeRef, {
          codeHash: getEmailOtpHash(email, code),
          expiresAt: admin.firestore.Timestamp.fromMillis(now + 5 * 60000),
          sentAt: admin.firestore.Timestamp.fromMillis(now),
          attempts: 0,
        });
      });

      try {
        await sendMail("email_otp", email, {otp: code});
        return {sent: true};
      } catch (error) {
        console.error("Email OTP delivery failed:", {
          message: error?.message || String(error),
          stack: error?.stack || null,
          code: error?.code || null,
          response: error?.response || null,
          responseCode: error?.responseCode || null,
        });
        await challengeRef.update({codeHash: null});
        if (error?.code === "EAUTH" ||
            error?.responseCode === 535 ||
            error?.responseCode === "535") {
          console.error("Titan blocked Firebase IP:", {
            host: "smtp.titan.email",
            responseCode: error?.responseCode || null,
          });
          throw new HttpsError(
              "unavailable",
              "Titan SMTP blocked from Cloud - use Gmail / SendGrid fallback",
          );
        }
        throw new HttpsError(
            "internal",
            error?.message || "Email delivery failed.",
        );
      }
    },
);

exports.verifyEmailOtp = onCall(async (request) => {
  const email = normalizeOtpEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();
  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError("invalid-argument", "The code is incorrect or expired.");
  }

  const db = admin.firestore();
  const challengeRef = db.collection("email_otp_challenges")
      .doc(getEmailOtpDocumentId(email));
  const now = Date.now();
  const verificationToken = crypto.randomBytes(32).toString("hex");
  let verified = false;
  await db.runTransaction(async (transaction) => {
    const challenge = await transaction.get(challengeRef);
    const data = challenge.data();
    if (!data || data.expiresAt.toMillis() <= now) {
      transaction.delete(challengeRef);
      return;
    }

    const attempts = Number(data.attempts || 0);
    if (attempts >= 5) {
      transaction.delete(challengeRef);
      return;
    }

    if (data.codeHash === getEmailOtpHash(email, code)) {
      transaction.update(challengeRef, {
        codeHash: null,
        verificationTokenHash:
            getEmailOtpVerificationTokenHash(email, verificationToken),
        verificationTokenExpiresAt:
            admin.firestore.Timestamp.fromMillis(now + 5 * 60000),
        attempts: 0,
      });
      verified = true;
      return;
    }

    if (attempts >= 4) {
      transaction.delete(challengeRef);
    } else {
      transaction.update(challengeRef, {attempts: attempts + 1});
    }
  });

  if (!verified) {
    throw new HttpsError("invalid-argument", "The code is incorrect or expired.");
  }
  return {verified: true, verificationToken};
});

exports.completeEmailOtpSignIn = onCall(async (request) => {
  const email = normalizeOtpEmail(request.data?.email);
  const verificationToken = String(request.data?.verificationToken || "").trim();
  if (!/^[a-f0-9]{64}$/i.test(verificationToken)) {
    throw new HttpsError("invalid-argument", "Verify your email code again.");
  }

  const challengeRef = admin.firestore()
      .collection("email_otp_challenges")
      .doc(getEmailOtpDocumentId(email));
  const now = Date.now();
  let tokenIsValid = false;
  await admin.firestore().runTransaction(async (transaction) => {
    const challenge = await transaction.get(challengeRef);
    const data = challenge.data();
    if (!data ||
        !data.verificationTokenExpiresAt ||
        data.verificationTokenExpiresAt.toMillis() <= now ||
        data.verificationTokenHash !==
            getEmailOtpVerificationTokenHash(email, verificationToken)) {
      return;
    }

    transaction.delete(challengeRef);
    tokenIsValid = true;
  });

  if (!tokenIsValid) {
    throw new HttpsError("invalid-argument", "Verify your email code again.");
  }

  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
    if (!user.emailVerified) {
      user = await admin.auth().updateUser(user.uid, {emailVerified: true});
    }
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw new HttpsError("internal", "Unable to sign in with this email.");
    }
    try {
      user = await admin.auth().createUser({email, emailVerified: true});
    } catch (createError) {
      if (createError.code !== "auth/email-already-exists") {
        throw new HttpsError("internal", "Unable to create your account.");
      }
      user = await admin.auth().getUserByEmail(email);
    }
  }

  return {customToken: await admin.auth().createCustomToken(user.uid)};
});
