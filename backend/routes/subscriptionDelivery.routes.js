import express from "express";
import {
  getDeliveryLogs,
  saveOrUpdateDeliveryConfig,
  regenerateDeliveryLogs,
  generateMonthlyDeliveryLogs,
  updateSingleDeliveryLog,
  getSubscriptionDeliveryById
} from "../controllers/subscriptionDelivery.controller.js";

import protect from "../middleware/auth.middleware.js";
import { isCustomer } from "../middleware/role.middleware.js";

const router = express.Router();

// Apply auth and role middleware to all delivery routes
router.use(protect, isCustomer);

// Create initial delivery config for a subscription
//router.post("/config/:subscriptionId", createDeliveryConfig);

// Get delivery logs for a subscription
router.get("/logs/:subscriptionId", getDeliveryLogs);

// Update delivery config (default days/quantities)
router.post("/config/:subscriptionId", saveOrUpdateDeliveryConfig);

// Regenerate future delivery logs based on updated config
router.post("/logs/:subscriptionId/regenerate", regenerateDeliveryLogs);

//update single delivery log 
router.post("/logs/override/:subscriptionId",updateSingleDeliveryLog);

// get subsription delivery by id
router.get('/full/:subscriptionId', getSubscriptionDeliveryById);


// Cron: Generate monthly delivery logs for all active subscriptions (system use)
//need to add security for this
router.post("/cron/generate-monthly", generateMonthlyDeliveryLogs);

export default router;
