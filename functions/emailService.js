const nodemailer = require("nodemailer");

async function sendMail(type, to, data) {
  try {
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASSWORD;
    if (!user || !pass) {
      throw new Error("SMTP_USER and SMTP_PASSWORD must be configured");
    }

    const transporter = nodemailer.createTransport({
      host: "smtp.titan.email",
      port: 465,
      secure: true,
      auth: {user, pass},
    });

    let subject; let html;

    // Define email content based on type
    switch (type) {
      case "payment_verified":
        subject = "Payment Successful";
        html = `
          <h2>Dear ${data.userName || "User"},</h2>
          <p>Your payment for the ${data.packageName} package has been successfully processed.</p>
          <p><strong>Transaction ID:</strong> ${data.transactionId}</p>
          <p><strong>Amount:</strong> PKR ${data.finalAmount}</p>
          <p>Thank you for using our service!</p>
        `;
        break;
      case "payment_rejected":
        subject = "Payment Failed";
        html = `
          <h2>Dear ${data.userName || "User"},</h2>
          <p>Unfortunately, your payment for the ${data.packageName} package could not be processed.</p>
          <p><strong>Transaction ID:</strong> ${data.transactionId}</p>
          <p><strong>Reason:</strong> ${data.reason || "Unknown error"}</p>
          <p>Please try again or contact support.</p>
        `;
        break;
      default:
        throw new Error(`Unsupported email type: ${type}`);
    }

    const info = await transporter.sendMail({
      from: "contact@nikahblessing.com",
      to,
      subject,
      html,
    });

    console.log("Email sent:", info.messageId);
    return {messageId: info.messageId};
  } catch (err) {
    console.error("Email sending error:", err);
    throw err;
  }
}

module.exports = {sendMail};
