import mongoose from "mongoose";

const subscriptionSchema = mongoose.Schema({
    subscribedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
    },
    productId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Product",
        required: true,
    },
});

export const Subscriptions = mongoose.model("Subscriptions", subscriptionSchema);