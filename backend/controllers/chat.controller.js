import { Chat } from "../models/chat.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";

// Get chat history for a user
const getChatHistory = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const chats = await Chat.find({ userId }).sort({ timestamp: -1 }).limit(50); // Get last 50 messages

  res.json(chats);
});

// Save a chat message
const saveMessage = asyncHandler(async (req, res) => {
  const { userId, content, type, metadata } = req.body;

  const chat = new Chat({
    userId,
    content,
    type,
    metadata,
  });

  await chat.save();
  res.status(201).json(chat);
});

// Get all chat messages for a user
const getAllMessages = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const chats = await Chat.find({ userId }).sort({ timestamp: 1 });
  res.json(chats);
});

// Delete chat history for a user
const deleteChatHistory = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  await Chat.deleteMany({ userId });
  res.json({ message: "Chat history deleted successfully" });
});

export { getChatHistory, saveMessage, getAllMessages, deleteChatHistory };
