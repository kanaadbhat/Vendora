import express from "express";
import { registerVendor, addCustomer, getVendorData } from "../controllers/vendorController.js";

const router = express.Router();

router.post("/register", registerVendor);
router.get("/getVendor/:phoneNumber",getVendorData)
router.post("/addCustomer", addCustomer);

export default router;
