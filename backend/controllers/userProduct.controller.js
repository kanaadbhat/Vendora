import {asyncHandler} from '../utils/asyncHandler.js'; 
import { Product } from "../models/product.model.js";
import {User} from "../models/user.model.js";
import {Subscriptions} from "../models/subscriptions.model.js";

//GET VENDOR PRODUCTS
const getVendorProducts = asyncHandler(async (req,res)=>{
    const vendorId = req.params.vendorId;
    const vendor = await User.findById(vendorId);
    if(!vendor){
        return res.status(200).json({ success: false, message: "Vendor not found" });
    };
    const products = await Product.find({createdBy:vendorId});
    res.status(200).json({success:true,products});
});

//SUBSCRIBE PRODUCTS
const subscribeProduct = asyncHandler(async (req, res) => {
    const { productId } = req.params;
    const userId = req.user._id;

    const product = await Product.findById(productId);
    if (!product) {
        return res.status(404).json({ success: false, message: "Product not found" });
    }

    const existingSubscription = await Subscriptions.findOne({ subscribedBy: userId, productId });
    if (existingSubscription) {
        return res.status(400).json({ success: false, message: "Already subscribed" });
    }

    await Subscriptions.create({ subscribedBy: userId, productId:productId });

    res.status(200).json({ success: true, message: "Subscribed to product" });
});

// GET ALL SUBSCRIBED PRODUCTS
const getSubscribedProducts = asyncHandler(async (req, res) => {
    const userId = req.user._id;

    const subscriptions = await Subscriptions.find({ subscribedBy: userId }).populate("productId");
    if (!subscriptions.length) {
        return res.status(404).json({ success: false, message: "No subscribed products found" });
    }

    const products = subscriptions.map(sub => sub.productId);
    
    res.status(200).json({ success: true, products });
});

// UNSUBSCRIBE FROM PRODUCT
const unsubscribeProduct = asyncHandler(async (req, res) => {
    const { productId } = req.params;
    const userId = req.user._id;

    const subscription = await Subscriptions.findOneAndDelete({ subscribedBy: userId, productId });

    if (!subscription) {
        return res.status(404).json({ success: false, message: "Subscription not found" });
    }

    res.status(200).json({ success: true, message: "Unsubscribed from product" });
});



export {getVendorProducts, subscribeProduct, getSubscribedProducts, unsubscribeProduct};