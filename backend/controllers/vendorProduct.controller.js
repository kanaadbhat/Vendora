import {asyncHandler} from '../utils/asyncHandler.js'; 
import { Product } from "../models/product.model.js";
import { User } from "../models/user.model.js";
import bcrypt from "bcryptjs";

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
    const { id } = req.params; 
    const { password } = req.body;
    const vendorId = req.user?._id; 

    if (!id) {
        return res.status(400).json({ 
            message: "Product ID is required", 
            success: false 
        });
    }

    if (!password) {
        return res.status(400).json({ 
            message: "Password is required to delete product", 
            success: false 
        });
    }

    if (!vendorId) {
        return res.status(401).json({ 
            message: "Unauthorized: User not found", 
            success: false 
        });
    }

    // Verify password
    const user = await User.findById(vendorId);
    if (!user || !(await bcrypt.compare(password, user.password))) {
        return res.status(401).json({ 
            message: "Invalid password", 
            success: false 
        });
    }

    const product = await Product.findById(id);

    if (!product) {
        return res.status(404).json({ 
            message: "Product not found", 
            success: false 
        });
    }

    if (product.createdBy.toString() !== vendorId.toString()) {
        return res.status(403).json({ 
            message: "Unauthorized: You can't delete this product", 
            success: false 
        });
    }

    await Product.findByIdAndDelete(id); 

    return res.status(200).json({ 
        message: "Product deleted successfully", 
        success: true 
    });
});


export {addProduct,getProducts, deleteProduct};