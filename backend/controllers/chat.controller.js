import { Chat } from "../models/chat.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";

// Get chat history for a user
const getChatHistory = asyncHandler(async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    const chats = await Chat.find({ userId : userId }).sort({ timestamp: -1 }).limit(50); // Get last 50 messages
    res.json(chats);
  } catch (error) {
    ApiError(res, error);
  }
});

// Save a chat message
const saveMessage = asyncHandler(async (req, res) => {
  try {
    const { userId, content, type, metadata } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    if (!content) {
      return res.status(400).json({ error: "Content is required" });
    }

    if (!type) {
      return res.status(400).json({ error: "Message type is required" });
    }

    const chat = new Chat({
      userId,
      content,
      type,
      metadata: metadata || {},
    });

    await chat.save();
    res.status(201).json(chat);
  } catch (error) {
    ApiError(res, error);
  }
});

// Get all chat messages for a user
const getAllMessages = asyncHandler(async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    const chats = await Chat.find({ userId }).sort({ timestamp: 1 });
    res.json(chats);
  } catch (error) {
    ApiError(res, error);
  }
});

// Delete chat history for a user
const deleteChatHistory = asyncHandler(async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    await Chat.deleteMany({ userId });
    res.json({ message: "Chat history deleted successfully" });
  } catch (error) {
    ApiError(res, error);
  }
});

export { getChatHistory, saveMessage, getAllMessages, deleteChatHistory };
