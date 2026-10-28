const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});
const crypto = require("crypto");
const axios = require("axios");
const nodemailer = require("nodemailer");
const querystring = require("querystring");
const {sendMail} = require("./emailService");

admin.initializeApp();

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
const BASE_URL =
  "https://onlinepayments.jazzcash.com.pk/payment-orchestrator/api/v2/rest/payments/m-wallet";

const transporter = nodemailer.createTransport({
  host: "smtpout.secureserver.net",
  port: 465,
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

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

function generateHash(data) {
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
        });

    if (userData.fcmToken) {
      await admin.messaging().send({
        token: userData.fcmToken,
        notification: {
          title: "Package Approved",
          body: "Your Package Successfully Subscribed",
          imageUrl: "imgurl",
        },
      });
    }

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

exports.initiateJazzCashPayment = functions.https.onRequest((req, res) => {
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

exports.jazzCashWebReturnUrl = functions.https.onRequest(jazzCashWebReturnHandler);

exports.jazzCashReturnUrl = functions.https.onRequest(async (req, res) => {
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
