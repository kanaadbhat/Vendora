import mongoose from 'mongoose';

const paymentSchema = mongoose.Schema({
    user_id: {
        type: String,
        required: true
    },
    order_id: {
        type: String,
        required: true,
        unique: true
    },
    payment_id: {
        type: String,
        required: true,
        unique: true
    },
    signature: {
        type: String,
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        required: true,
        default: 'INR'
    },
    status: {
        type: String,
        required: true,
        enum: ['success', 'failed', 'pending', 'cancelled'],
        default: 'pending'
    },
    method: {
        type: String,
        required: true,
        enum: ['card', 'upi', 'wallet', 'netbanking', 'other']
    },
    receipt: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    from: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    to: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: false // Make it optional
    }
}, {
    timestamps: true // This will add createdAt and updatedAt fields
});

// Index for better query performance
paymentSchema.index({ from: 1, createdAt: -1 });
paymentSchema.index({ to: 1, createdAt: -1 });
paymentSchema.index({ user_id: 1, createdAt: -1 });

export const Payment = mongoose.model('Payment', paymentSchema);
