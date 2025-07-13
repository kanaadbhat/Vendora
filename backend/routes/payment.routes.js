import express from "express";
import {
    createOrder,
    verifyPayment,
    getAllPayments,
} from "../controllers/payment.controller.js";
import protect from "../middleware/auth.middleware.js";
import { isCustomer } from "../middleware/role.middleware.js";

const router = express.Router();
//router.use(protect, isCustomer);

router.post("/create-order", createOrder);

router.post("/verify-payment", protect, verifyPayment);

router.get("/all", protect, getAllPayments);

export default router;