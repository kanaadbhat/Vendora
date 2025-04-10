import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import { SubscriptionDeliveries } from "../models/subscriptionDeliveries.model.js";
import { Subscriptions } from "../models/subscriptions.model.js";
import { DateTime } from "luxon";

// Helper to generate logs
const generateLogsForPeriod = (startDate, endDate, config) => {
  const dayMap = {
    sunday: 7,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
  };

  const allowedDayIndices = config.days.map((d) => dayMap[d.toLowerCase()]);
  const logs = [];

  let current = startDate.startOf("day");
  const end = endDate.endOf("day");

  while (current <= end) {
    const dayOfWeek = current.weekday;

    if (allowedDayIndices.includes(dayOfWeek)) {
      const deliveryTime = current.set({ hour: 18, minute: 30, second: 0, millisecond: 0 });

      logs.push({
        date: deliveryTime.toUTC().toISO(), // store in UTC
        quantity: config.quantity,
        delivered: false,
        cancelled: false,
      });
    }

    current = current.plus({ days: 1 });
  }

  return logs;
};

// Save or update config + regenerate logs
export const saveOrUpdateDeliveryConfig = asyncHandler(async (req, res) => {
  const { subscriptionId } = req.params;
  const { days, quantity } = req.body;

  if (!days || !quantity)
    throw new ApiError(400, "days and quantity are required");

  const subscription = await Subscriptions.findById(subscriptionId);
  if (!subscription) throw new ApiError(404, "Subscription not found");

  const config = { days, quantity };

  const now = DateTime.now().setZone("Asia/Kolkata");
  const start = now.startOf("day");
  const end = now.endOf("month");

  const newLogs = generateLogsForPeriod(start, end, config);

  const existing = await SubscriptionDeliveries.findOne({ subscriptionId });

  if (existing) {
    existing.deliveryConfig = config;
    existing.deliveryLogs = [
      ...existing.deliveryLogs.filter((log) =>
        DateTime.fromISO(log.date) < start
      ),
      ...newLogs,
    ];
    await existing.save();
  } else {
    await SubscriptionDeliveries.create({
      subscriptionId,
      deliveryConfig: config,
      deliveryLogs: newLogs,
    });
  }

  return res.status(200).json(
    new ApiResponse(
      200,
      null,
      existing
        ? "Config updated and future logs regenerated"
        : "Config saved and logs generated"
    )
  );
});

// Get logs
export const getDeliveryLogs = asyncHandler(async (req, res) => {
  const { subscriptionId } = req.params;

  const doc = await SubscriptionDeliveries.findOne({ subscriptionId });
  if (!doc) throw new ApiError(404, "Delivery data not found");

  return res
    .status(200)
    .json(new ApiResponse(200, doc.deliveryLogs, "Logs fetched successfully"));
});

// Update a single log (cancel or modify quantity)
export const updateSingleDeliveryLog = asyncHandler(async (req, res) => {
  const { subscriptionId } = req.params;
  const { date, cancel = false, quantity } = req.body;

  if (!date) {
    throw new ApiError(400, "Date is required.");
  }

  const delivery = await SubscriptionDeliveries.findOne({ subscriptionId });
  if (!delivery) {
    throw new ApiError(404, "No delivery configuration found for this subscription.");
  }

  const requestedDate = DateTime.fromISO(date, { zone: "Asia/Kolkata" }).startOf("day");
  const now = DateTime.now().setZone("Asia/Kolkata");

  // Ensure that modification is being done at least a day in advance (before 12 PM)
  const tomorrow = now.plus({ days: 1 }).startOf("day");
  if (requestedDate <= now.startOf("day")) {
    throw new ApiError(400, "Cannot update past or today's delivery.");
  }

  if (requestedDate.equals(tomorrow) && now.hour >= 12) {
    throw new ApiError(400, "Too late to modify tomorrow's delivery. Must be done before 12 PM.");
  }

  // Find the matching delivery log by date (normalize to IST day)
  const targetLog = delivery.deliveryLogs.find((log) => {
    const logDate = DateTime.fromJSDate(log.date).setZone("Asia/Kolkata").startOf("day");
    return logDate.toISODate() === requestedDate.toISODate();
  });

  if (!targetLog) {
    throw new ApiError(404, "No scheduled delivery found for the given date.");
  }

  if (targetLog.delivered) {
    throw new ApiError(400, "Cannot modify a delivery that has already been marked as delivered.");
  }

  // Apply cancellation or quantity update
  if (cancel) {
    targetLog.cancelled = true;
  } else if (typeof quantity === "number") {
    if (targetLog.cancelled) {
      throw new ApiError(400, "Cannot update quantity of a cancelled delivery.");
    }
    targetLog.quantity = quantity;
  } else {
    throw new ApiError(400, "Either cancel or a valid quantity must be provided.");
  }

  await delivery.save();

  return res.status(200).json(
    new ApiResponse(200, null, "Delivery log updated successfully.")
  );
});

/*
// Regenerate logs for current month for one subscription
export const regenerateDeliveryLogs = asyncHandler(async (req, res) => {
  const { subscriptionId } = req.params;

  const doc = await SubscriptionDeliveries.findOne({ subscriptionId });
  if (!doc) throw new ApiError(404, "Delivery config not found");

  const now = DateTime.now().setZone("Asia/Kolkata");
  const start = now.startOf("month");
  const end = now.endOf("month");

  const newLogs = generateLogsForPeriod(start, end, doc.deliveryConfig);

  doc.deliveryLogs = [
    ...doc.deliveryLogs.filter((log) =>
      DateTime.fromISO(log.date) < start
    ),
    ...newLogs,
  ];

  await doc.save();

  return res
    .status(200)
    .json(new ApiResponse(200, null, "Logs regenerated for current month"));
});
*/

// Generate logs for current month for all subscriptions
export const generateMonthlyDeliveryLogs = asyncHandler(async (req, res) => {
  const now = DateTime.now().setZone("Asia/Kolkata");
  const start = now.startOf("month");
  const end = now.endOf("month");

  const all = await SubscriptionDeliveries.find({});

  for (const doc of all) {
    const newLogs = generateLogsForPeriod(start, end, doc.deliveryConfig);

    doc.deliveryLogs = [
      ...doc.deliveryLogs.filter((log) =>
        DateTime.fromISO(log.date) < start
      ),
      ...newLogs,
    ];

    await doc.save();
  }

  return res
    .status(200)
    .json(new ApiResponse(200, null, "Monthly delivery logs generated"));
});
