import express from "express";
import dotenv from "dotenv";
import admin from "firebase-admin";
import routes from "./routes/index.js"; // Import all routes


// Express App Setup
const app = express();
app.use(express.json());

// Use the routes
app.use("/api", routes);

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
