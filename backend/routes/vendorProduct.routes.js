import { Router } from 'express';
import { addProduct, getProducts, deleteProduct } from '../controllers/vendorProduct.controller.js';
import protect from "../middleware/auth.middleware.js";
import { isVendor } from "../middleware/role.middleware.js";

const router = Router();

// All routes require authentication and vendor role
router.use(protect, isVendor);

// Product routes
router.route('/add').post(addProduct);
router.route('/all').get(getProducts);
router.route('/delete/:id').delete(deleteProduct);

export default router;