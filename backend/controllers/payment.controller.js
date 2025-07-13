import Razorpay from "razorpay";
import crypto from "crypto";
import { asyncHandler } from "../utils/asyncHandler.js";
import { Payment } from "../models/payment.model.js";
import dotenv from "dotenv";
import mongoose from "mongoose";

dotenv.config();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_SECRET,
});

const createOrder = asyncHandler(async (req, res) => {
  const { amount, currency, receipt } = req.body;

  const options = {
    amount: amount * 100, // Convert to paise
    currency,
    receipt,
    payment_capture: 1,
  };

  try {
    const order = await razorpay.orders.create(options);
    res.status(200).send({
      message: "Order created",
      success: true,
      details: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
      },
    });
  } catch (err) {
    res.status(500).send({ success: false, message: err.message });
  }
});

const verifyPayment = asyncHandler(async (req, res) => {
  const { 
    razorpay_order_id, 
    razorpay_payment_id, 
    razorpay_signature,
    amount,
    currency,
    receipt,
    description,
    from,
    to,
    method = "other",
  } = req.body;

  const hmac = crypto.createHmac("sha256", process.env.RAZORPAY_SECRET);
  hmac.update(`${razorpay_order_id}|${razorpay_payment_id}`);
  const digest = hmac.digest("hex");

  if (digest === razorpay_signature) {
    try {
      // Check if payment already exists to prevent duplicates
      const existingPayment = await Payment.findOne({ order_id: razorpay_order_id });
      if (existingPayment) {
        return res.json({ 
          success: true, 
          message: "Payment already verified and stored",
          payment: existingPayment,
        });
      }

      // Prepare payment data
      const paymentData = {
        user_id: req.user._id, // Current user ID
        order_id: razorpay_order_id,
        payment_id: razorpay_payment_id,
        signature: razorpay_signature,
        amount: amount,
        currency: currency || "INR",
        status: "success",
        method: method,
        receipt: receipt,
        description: description,
        from: from, // Customer ID
      };

      // Only add 'to' field if it's a valid ObjectId
      if (to && to !== 'vendor_id_placeholder' && mongoose.Types.ObjectId.isValid(to)) {
        paymentData.to = to;
      }

      // Store payment details in database
      const payment = new Payment(paymentData);
      await payment.save();

      return res.json({ 
        success: true, 
        message: "Payment Verified and Stored",
        payment: payment,
      });
    } catch (error) {
      console.error("Error storing payment:", error);
      
      // Handle duplicate key error specifically
      if (error.code === 11000) {
        return res.json({ 
          success: true, 
          message: "Payment already verified and stored",
        });
      }
      
      return res.status(500).json({ 
        success: false, 
        message: "Payment verified but failed to store in database",
      });
    }
  } else {
    return res
      .status(400)
      .send({ success: false, message: "Invalid signature" });
  }
});

const getAllPayments = asyncHandler(async (req, res) => {
  try {
    const user = req.user;
    let payments;

    if (user.role === "customer") {
      // For customers, get all payments where FROM is the user
      payments = await Payment.find({ from: user._id })
        .populate("to", "name email businessName")
        .populate("from", "name email")
        .sort({ createdAt: -1 }); // Latest first
    } else if (user.role === "vendor") {
      // For vendors, get all payments where TO is the user
      payments = await Payment.find({ to: user._id })
        .populate("to", "name email businessName")
        .populate("from", "name email")
        .sort({ createdAt: -1 }); // Latest first
    } else {
      return res.status(403).json({
        success: false,
        message: "Access denied. Only customers and vendors can view payments.",
      });
    }

    res.status(200).json({
      success: true,
      message: "Payments retrieved successfully",
      data: payments,
      count: payments.length,
    });
  } catch (error) {
    console.error("Error fetching payments:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching payments",
      error: error.message,
    });
  }
});

export { createOrder, verifyPayment, getAllPayments };
