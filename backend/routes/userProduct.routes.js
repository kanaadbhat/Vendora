import {Router} from 'express';
import { getVendorProducts, subscribeProduct, getSubscribedProducts, unsubscribeProduct} from '../controllers/userProduct.controller.js';
import protect from "../middleware/auth.middleware.js";

const router= Router();
router.get("/getVendorProducts/:vendorId", protect,getVendorProducts);
router.post("/subscribeProduct/:productId",protect,subscribeProduct);
router.get("/getSubscribedProducts", protect, getSubscribedProducts);
router.post("/unsubscribeProduct/:productId",protect,unsubscribeProduct);

export default router;
