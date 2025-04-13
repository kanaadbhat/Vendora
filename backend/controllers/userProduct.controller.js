import {asyncHandler} from '../utils/asyncHandler.js'; 
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Product } from "../models/product.model.js";
import {User} from "../models/user.model.js";
import {Subscriptions} from "../models/subscriptions.model.js";
import bcrypt from 'bcryptjs';
import {SubscriptionDeliveries} from "../models/subscriptionDeliveries.model.js";


/*
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
*/
// Get all registered vendors
const getAllVendors = asyncHandler(async (req, res) => {
  const vendors = await User.find({ role: "vendor" });
  
  if (!vendors.length) {
    throw new ApiError(404, "No vendors found");
  }

  return res.status(200).json(
    new ApiResponse(200, vendors, "Vendors fetched successfully")
  );
});

// Get products by vendor
const getVendorProducts = asyncHandler(async (req, res) => {
  const { vendorId } = req.params;
  
  // Check if vendor exists
  const vendor = await User.findOne({ _id: vendorId, role: "vendor" });
  if (!vendor) {
    throw new ApiError(404, "Vendor not found");
  }

  const products = await Product.find({ createdBy: vendorId });
  if (!products.length) {
    throw new ApiError(404, "No products found for this vendor");
  }

  return res.status(200).json(
    new ApiResponse(200, products, "Vendor products fetched successfully")
  );
});

// Get all subscriptions for a user
const getAllSubscriptions = asyncHandler(async (req, res) => {
  const subscriptions = await Subscriptions.find({ subscribedBy: req.user._id });
  
  if (!subscriptions.length) {
    throw new ApiError(404, "No subscriptions found");
  }

  return res.status(200).json(
    new ApiResponse(200, subscriptions, "Subscriptions fetched successfully")
  );
});

// Subscribe to a product
const subscribeToProduct = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { password } = req.body;

  // Verify user password
  const user = await User.findById(req.user._id);
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new ApiError(401, "Invalid password");
  }

  // Check if already subscribed
  const existingSubscription = await Subscriptions.findOne({
    subscribedBy: req.user._id,
    productId: productId,
  });

  if (existingSubscription) {
    throw new ApiError(400, "Already subscribed to this product");
  }

  // Get product details
  const product = await Product.findById(productId);
  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  // Get vendor details
  const vendor = await User.findById(product.createdBy);
  if (!vendor) {
    throw new ApiError(404, "Vendor not found");
  }

  // Create subscription with all details
  const subscription = await Subscriptions.create({
    subscribedBy: req.user._id,
    productId: product._id,
    name: product.name,
    description: product.description,
    price: product.price,
    image: product.image,
    vendorId: vendor._id,
    vendorName: vendor.name,
    createdAt: new Date(),
  });

  return res.status(201).json(
    new ApiResponse(201, subscription, "Successfully subscribed to product")
  );
});

// Unsubscribe from a product
const unsubscribeFromProduct = asyncHandler(async (req, res) => {
  const { subscriptionId } = req.params;
  const { password } = req.body;

  const user = await User.findById(req.user._id);
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    throw new ApiError(401, "Invalid password");
  }

  const subscription = await Subscriptions.findOne({
    _id: subscriptionId,
    subscribedBy: req.user._id,
  });

  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  await subscription.deleteOne();

  await SubscriptionDeliveries.deleteOne({ subscriptionId });

  return res.status(200).json(
    new ApiResponse(200, null, "Successfully unsubscribed from product")
  );
});


export {
  getAllVendors,
  getVendorProducts,
  getAllSubscriptions,
  subscribeToProduct,
  unsubscribeFromProduct,
};