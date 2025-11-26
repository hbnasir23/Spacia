const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// 1. Configure your email account (Gmail example)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "hbnasir2023@gmail.com",       // your email
    pass: "geyk ucwl xafb ybkt",          // NOT your Gmail password
  },
});

// 2. Cloud Function that triggers when a new email doc is created
exports.sendMail = onDocumentCreated("mail/{docId}", async (event) => {
  const data = event.data.data();

  const mailOptions = {
    from: "Spacia <hbnasir2023@gmail.com>",
    to: data.to,
    subject: data.message.subject,
    html: data.message.html,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log("Email sent!");
  } catch (error) {
    console.error("Error sending email:", error);
  }
});
