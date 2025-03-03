import express from "express";
import vendorRoutes from "./vendorRoutes.js";

const router = express.Router();

// Use vendor-related routes
router.use("/", vendorRoutes);


export default router;
