import express from "express";
import {
    createOrder,
    verifyPayment,
} from "../controllers/payment.controller.js";
import protect from "../middleware/auth.middleware.js";
import { isCustomer } from "../middleware/role.middleware.js";

const router = express.Router();
//router.use(protect, isCustomer);

router.post("/create-order", createOrder);

router.post("/verify-payment", verifyPayment);

export default router;