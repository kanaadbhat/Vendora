import express from "express";
import {
  getChatHistory,
  saveMessage,
  getAllMessages,
  deleteChatHistory,
} from "../controllers/chat.controller.js";
import protect from "../middleware/auth.middleware.js";

const router = express.Router();
// Apply authentication middleware to all routes
router.use(protect);

// Get chat history
router.get("/:userId", getChatHistory);

// Save a message
router.post("/", saveMessage);

// Get all messages
router.get("/:userId/all", getAllMessages);

// Delete chat history
router.delete("/:userId", deleteChatHistory);

// Error handling middleware
router.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: err.message,
  });
});

export default router;
