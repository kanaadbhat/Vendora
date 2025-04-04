import express from "express";
import {
  getAllVendors,
  getVendorProducts,
  getAllSubscriptions,
  subscribeToProduct,
  unsubscribeFromProduct,
} from "../controllers/userProduct.controller.js";
import protect from "../middleware/auth.middleware.js";
import { isCustomer } from "../middleware/role.middleware.js";

const router = express.Router();

// Apply auth and role middleware to all routes
router.use(protect, isCustomer);

// Get all registered vendors
router.get("/vendors", getAllVendors);

// Get products by vendor
router.get("/vendors/:vendorId/products", getVendorProducts);

// Get all subscriptions for the logged-in user
router.get("/all", getAllSubscriptions);

// Subscribe to a product
router.post("/subscribe/:productId", subscribeToProduct);

// Unsubscribe from a product
router.delete("/unsubscribe/:subscriptionId", unsubscribeFromProduct);

export default router;
