import mongoose from 'mongoose';

const chatSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required'],
  },
  content: {
    type: String,
    required: [true, 'Content is required'],
  },
  type: {
    type: String,
    enum: {
      values: ['user', 'ai', 'system', 'error'],
      message: '{VALUE} is not a valid message type',
    },
    required: [true, 'Message type is required'],
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {},
  },
}, {
  timestamps: true,
});

// Add index for faster queries
chatSchema.index({ userId: 1, timestamp: -1 });

export const Chat = mongoose.model("Chat", chatSchema);