import mongoose from "mongoose";

const deliveryLogSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
    },
    delivered: {
      type: Boolean,
      default: false,
    },
    cancelled: {
      type: Boolean,
      default: false,
    },
  },
  { _id: false }
);

const deliveryConfigSchema = new mongoose.Schema(
  {
    days: {
      type: [String], // e.g., ["monday", "wednesday", "friday"]
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
    },
  },
  { _id: false }
);

const subscriptionDeliverySchema = new mongoose.Schema(
  {
    subscriptionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subscriptions",
      required: true,
      unique: true,
    },
    deliveryConfig: {
      type: deliveryConfigSchema,
      required: true,
    },
    deliveryLogs: [deliveryLogSchema],
  },
  {
    timestamps: true,
  }
);

export const SubscriptionDeliveries = mongoose.model(
  "SubscriptionDeliveries",
  subscriptionDeliverySchema
);
