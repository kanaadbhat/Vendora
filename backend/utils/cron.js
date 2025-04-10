import cron from "node-cron";
import axios from "axios";
import dotenv from "dotenv";
import { SubscriptionDeliveries } from "../models/subscriptionDeliveries.model.js";
import { DateTime } from "luxon";

dotenv.config();

const API_URL =
  process.env.CRON_API_URL || "http://localhost:8000/api/delivery/cron/generate-monthly";

// 👇 Function to mark past undelivered, un-cancelled deliveries as delivered
const processDeliveryLogs = async () => {
  const today = DateTime.now().setZone("Asia/Kolkata").startOf("day");

  const deliveries = await SubscriptionDeliveries.find({
    deliveryLogs: {
      $elemMatch: {
        date: { $lt: today.toJSDate() },
        delivered: false,
        cancelled: false,
      },
    },
  });

  for (const delivery of deliveries) {
    for (let log of delivery.deliveryLogs) {
      const logDate = DateTime.fromJSDate(log.date);
      if (logDate < today && !log.delivered && !log.cancelled) {
        log.delivered = true;
      }
    }
    await delivery.save();
  }

  console.log("Delivery logs processed.");
};

//  Monthly: Generate delivery logs on 1st of each month at 12:10 AM
cron.schedule("10 0 1 * *", async () => {
  console.log("⏳ Running monthly delivery log generation...");

  try {
    const res = await axios.post(API_URL);
    console.log(" Monthly logs generated:", res.data.message);
  } catch (err) {
    console.error(" Monthly cron job failed:", err.message);
  }
});

// Daily: Process logs at 12:05 AM IST to mark missed deliveries as delivered
cron.schedule("35 18 * * *", async () => {
  console.log(" Running daily delivery status update...");

  try {
    await processDeliveryLogs();
  } catch (err) {
    console.error(" Daily delivery log processing failed:", err.message);
  }
});
