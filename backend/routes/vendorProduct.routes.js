import {Router} from 'express';
import {addProduct,getProducts,deleteProduct } from '../controllers/vendorProduct.controller.js';
import protect from "../middleware/auth.middleware.js";

 const router= Router();
router.post('/addProduct', protect, addProduct);
router.get('/getProducts', protect, getProducts);
router.delete("/deleteProduct/:id", protect, deleteProduct);



export default router;