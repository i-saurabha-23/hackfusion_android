require("dotenv").config();
const express = require("express");
const nodemailer = require("nodemailer");
const multer = require("multer");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 5000;

// Configure multer for memory storage
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

// Middleware
app.use(cors({
    origin: '*', // Be more specific in production
    methods: ['POST', 'GET'],
    allowedHeaders: ['Content-Type']
}));
app.use(express.json());

// Email Transporter Setup
const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

// Handle multipart form data with file upload
app.post("/send-email", upload.single('proofFile'), async (req, res) => {
    try {
        const { name, email, facultyEmail, reason, startDate, endDate, duration } = req.body;

        // Validate input
        if (!name || !email || !facultyEmail || !reason || !startDate || !endDate || !duration) {
            return res.status(400).json({ error: "Missing required fields." });
        }

        // Format dates for email
        const formattedStartDate = new Date(startDate).toLocaleDateString();
        const formattedEndDate = new Date(endDate).toLocaleDateString();

        // Prepare email options
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: facultyEmail,
            subject: `Leave Application from ${name}`,
            html: `
                <p><strong>Student Name:</strong> ${name}</p>
                <p><strong>Student Email:</strong> ${email}</p>
                <p><strong>Leave Period:</strong> ${formattedStartDate} to ${formattedEndDate}</p>
                <p><strong>Duration:</strong> ${duration} days</p>
                <p><strong>Reason:</strong> ${reason}</p>
                ${req.file ? '<p><strong>Supporting Document:</strong> Attached</p>' : ''}
                <p>Kindly review and process the leave request.</p>
            `
        };

        // If file was uploaded, attach it to the email
        if (req.file) {
            mailOptions.attachments = [{
                filename: req.file.originalname || 'supporting_document',
                content: req.file.buffer
            }];
        }

        // Send email
        await transporter.sendMail(mailOptions);
        res.status(200).json({
            success: "Leave application submitted successfully and email sent!"
        });

    } catch (error) {
        console.error('Error processing request:', error);
        res.status(500).json({
            error: "Failed to process request",
            details: error.message
        });
    }
});

// ✅ Handle multipart form data with file upload
app.post("/send-medical-email", upload.single("proofFile"), async (req, res) => {
    try {
        const {
            name,
            email,
            facultyEmail,
            parentEmail,
            startDate,
            endDate,
            duration,
            bedRestSuggested,
            bedRestDays,
            bedRestStartDate,
            bedRestEndDate,
        } = req.body;

        // ✅ Validate required fields
        if (!name || !email || !facultyEmail || !startDate || !endDate || !duration || !parentEmail) {
            return res.status(400).json({ error: "Missing required fields." });
        }

        // ✅ Format dates for email
        const formattedStartDate = new Date(startDate).toLocaleDateString();
        const formattedEndDate = new Date(endDate).toLocaleDateString();
        const formattedBedRestStart = bedRestStartDate ? new Date(bedRestStartDate).toLocaleDateString() : "N/A";
        const formattedBedRestEnd = bedRestEndDate ? new Date(bedRestEndDate).toLocaleDateString() : "N/A";

        // ✅ Construct email content
        let emailBody = `
            <p><strong>Student Name:</strong> ${name}</p>
            <p><strong>Student Email:</strong> ${email}</p>
            <p><strong>Leave Period:</strong> ${formattedStartDate} to ${formattedEndDate}</p>
            <p><strong>Duration:</strong> ${duration} days</p>
        `;

        // ✅ Include Bed Rest details if applicable
        if (bedRestSuggested === "true") {
            emailBody += `
                <p><strong>Bed Rest Suggested:</strong> Yes</p>
                <p><strong>Total Bed Rest Days:</strong> ${bedRestDays} days</p>
                <p><strong>Bed Rest Start Date:</strong> ${formattedBedRestStart}</p>
                <p><strong>Bed Rest End Date:</strong> ${formattedBedRestEnd}</p>
            `;
        } else {
            emailBody += `<p><strong>Bed Rest Suggested:</strong> No</p>`;
        }

        // ✅ Add file attachment message if file exists
        if (req.file) {
            emailBody += `<p><strong>Supporting Document:</strong> Attached</p>`;
        }

        emailBody += `<p>Kindly review and process the leave request.</p>`;

        // ✅ Configure email options
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: `${facultyEmail}, ${email}, ${parentEmail}`, // Send to multiple recipients
            subject: `Medical Leave Application from ${name}`,
            html: emailBody,
        };

        // ✅ Attach file if uploaded
        if (req.file) {
            mailOptions.attachments = [
                {
                    filename: req.file.originalname || "supporting_document",
                    content: req.file.buffer,
                },
            ];
        }

        // ✅ Send the email
        await transporter.sendMail(mailOptions);

        res.status(200).json({
            success: "Leave application submitted successfully and email sent!",
        });
    } catch (error) {
        console.error("Error processing request:", error);
        res.status(500).json({
            error: "Failed to process request",
            details: error.message,
        });
    }
});

// Handle multipart form data with file upload
app.post("/leave-status", upload.single('proofFile'), async (req, res) => {
    try {
        const { name, email, facultyEmail, reason, parentEmail, startDate, endDate, duration, status } = req.body;

        // Validate input
        if (!name || !email || !facultyEmail || !startDate || !endDate || !duration || !parentEmail || !status || !reason) {
            return res.status(400).json({ error: "Missing required fields." });
        }

        // Format dates for email
        const formattedStartDate = new Date(startDate).toLocaleDateString();
        const formattedEndDate = new Date(endDate).toLocaleDateString();

        // Construct email subject based on status
        let subject = `Leave Application ${status} - ${name}`;
        let body = `
            <p><strong>Student Name:</strong> ${name}</p>
            <p><strong>Student Email:</strong> ${email}</p>
            <p><strong>Leave Period:</strong> ${formattedStartDate} to ${formattedEndDate}</p>
            <p><strong>Reason:</strong> ${reason}</p>
            <p><strong>Duration:</strong> ${duration} days</p>
        `;

        if (status === "Approved") {
            body += `<p><strong>Status:</strong> ✅ Approved</p>`;
            body += `<p>Your leave request has been approved by the administration.</p>`;
        } else if (status === "Rejected") {
            body += `<p><strong>Status:</strong> ❌ Rejected</p>`;
            body += `<p>Your leave request has been denied. Please contact your faculty for more details.</p>`;
        }

        body += `<p>If you have any questions, please reach out to the faculty coordinator at ${facultyEmail}.</p>`;

        // Define email recipients
        const recipients = `${email}, ${parentEmail}`;

        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: recipients, // Send to student & parent
            subject: subject,
            html: body,
        };

        // If file was uploaded, attach it to the email
        if (req.file) {
            mailOptions.attachments = [{
                filename: req.file.originalname || 'supporting_document',
                content: req.file.buffer
            }];
        }

        // Send email
        await transporter.sendMail(mailOptions);

        res.status(200).json({
            success: `Leave ${status.toLowerCase()} successfully and email sent to Student & Parent!`
        });

    } catch (error) {
        console.error('Error processing request:', error);
        res.status(500).json({
            error: "Failed to process request",
            details: error.message
        });
    }
});

// Basic health check endpoint
app.get('/', (req, res) => {
    res.send('Server is running');
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    if (err instanceof multer.MulterError) {
        // Handle multer-specific errors
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                error: 'File is too large. Maximum size is 5MB.'
            });
        }
        return res.status(400).json({ error: err.message });
    }
    res.status(500).json({ error: 'Something went wrong!' });
});

// Start the server
app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server is running on http://0.0.0.0:${PORT}`);
});