import {asyncHandler} from '../utils/asyncHandler.js'; 
import { Product } from "../models/product.model.js";
import { User } from "../models/user.model.js";
import bcrypt from "bcryptjs";
import { Subscriptions } from "../models/subscriptions.model.js";
import { SubscriptionDeliveries } from "../models/subscriptionDeliveries.model.js";

//ADD PRODUCT BY VENDOR
const addProduct = asyncHandler(async (req, res) =>{
    const {name, description, price,image} = req.body;
    
    if (!name || !description || !price || !image) {
        return res.status(400).json({
            message: "Please provide all required fields",
            success: false
        });
    }

    if (price <= 0) {
        return res.status(400).json({
            message: "Price must be greater than 0",
            success: false
        });
    }

    if (!req.user || !req.user._id) {
        return res.status(401).send({
            message: "Unauthorized: User not found",
            success: false
        });
    }
    const product = await Product.create({
        name,
        description,
        price,
        image,
        createdBy:req.user._id
    });
    await product.save();
    return res.status(201).send({
        message : "Product added successfully",
        success : true,
        product
    })
});

//GET ALL PRODUCTS OF VENDOR
const getProducts = asyncHandler(async (req, res) => {
    const userId = req.user._id; 

    const products = await Product.find({ createdBy: userId })
        .sort({ createdAt: -1 }); // Sort by newest first

    return res.status(200).json({
        success: true,
        products
    });
});

//DELETE PRODUCT 
const deleteProduct = asyncHandler(async (req, res) => {
    const { id } = req.params; // Product ID
    const { password } = req.body;
    const vendorId = req.user?._id;
  
    if (!id) {
      return res.status(400).json({
        message: "Product ID is required",
        success: false,
      });
    }
  
    if (!password) {
      return res.status(400).json({
        message: "Password is required to delete product",
        success: false,
      });
    }
  
    if (!vendorId) {
      return res.status(401).json({
        message: "Unauthorized: User not found",
        success: false,
      });
    }
  
    // Verify password
    const user = await User.findById(vendorId);
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({
        message: "Invalid password",
        success: false,
      });
    }
  
    const product = await Product.findById(id);
  
    if (!product) {
      return res.status(404).json({
        message: "Product not found",
        success: false,
      });
    }
  
    if (product.createdBy.toString() !== vendorId.toString()) {
      return res.status(403).json({
        message: "Unauthorized: You can't delete this product",
        success: false,
      });
    }
  
    // Step 1: Delete all subscriptions related to this product
    const subscriptions = await Subscriptions.find({ productId: id });
    const subscriptionIds = subscriptions.map(sub => sub._id);
  
    await Subscriptions.deleteMany({ productId: id });
  
    // Step 2: Delete all subscription deliveries for those subscriptions
    if (subscriptionIds.length > 0) {
      await SubscriptionDeliveries.deleteMany({ subscriptionId: { $in: subscriptionIds } });
    }
  
    // Step 3: Delete the product
    await Product.findByIdAndDelete(id);
  
    return res.status(200).json({
      message: "Product and associated subscriptions/deliveries deleted successfully",
      success: true,
    });
  });
  
//GET VENDOR PRODUCTS WITH SUBSCRIBERS AND DELIVERY DETAILS
const getProductsWithSubscribers = asyncHandler(async (req, res) => {
  const vendorId = req.user._id;

  if (!vendorId) {
    return res.status(401).json({
      message: "Unauthorized: User not found",
      success: false,
    });
  }

  const products = await Product.find({ createdBy: vendorId });
  
  const productsWithSubscribers = [];
  
  for (const product of products) {
    const subscriptions = await Subscriptions.find({ productId: product._id })
      .populate({
        path: 'subscribedBy',
        select: 'name email phone' 
      });
    
    const subscriptionsWithDeliveries = [];
    
    for (const subscription of subscriptions) {
      const deliveryDetails = await SubscriptionDeliveries.findOne({ 
        subscriptionId: subscription._id 
      });
      
      subscriptionsWithDeliveries.push({
        subscription,
        deliveryDetails
      });
    }
    
    productsWithSubscribers.push({
      product,
      subscribers: subscriptionsWithDeliveries
    });
  }
  
  return res.status(200).json({
    success: true,
    productsWithSubscribers
  });
});

export {addProduct, getProducts, deleteProduct, getProductsWithSubscribers};