import { User } from "../models/user.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import { validateEmail, validatePhone } from "../utils/validators.js";

//SIGNIN
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).send({
      message: "Please provide email and password",
      success: false,
    });
  }

  if (!validateEmail(email)) {
    return res.status(400).send({
      message: "Please provide a valid email address",
      success: false,
    });
  }

  const user = await User.findOne({ email });

  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(400).send({
      message: "Incorrect email or password",
      success: false,
    });
  }

  const accessToken = jwt.sign(
    { 
      id: user._id,
      role: user.role 
    },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  const refreshToken = jwt.sign(
    { 
      id: user._id,
      role: user.role 
    },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );

  return res.status(200).send({
    message: "Login successful",
    success: true,
    accessToken,
    refreshToken,
    user: {
      _id: user._id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role,
      businessName: user.businessName,
      businessDescription: user.businessDescription,
      profileimage:user.profileimage
    },
  });
});

//SIGNUP
const register = asyncHandler(async (req, res) => {
  const {
    email,
    password,
    name,
    phone,
    role,
    businessName,
    businessDescription,
    profileimage
  } = req.body;

  // Validate inputs
  if (!validateEmail(email)) {
    return res.status(400).send({
      message: "Please provide a valid email address",
      success: false,
    });
  }

  if (!validatePhone(phone)) {
    return res.status(400).send({
      message: "Please provide a valid phone number",
      success: false,
    });
  }

  if (password.length < 6) {
    return res.status(400).send({
      message: "Password must be at least 6 characters long",
      success: false,
    });
  }

  const check = await User.findOne({ email });
  if (check) {
    return res.status(400).send({
      message: "User already exists",
      success: false,
    });
  }

  let user;
  if (role === "customer") {
    if (!email || !password || !name || !phone || !profileimage)  {
      return res.status(400).send({
        message: "Please provide all fields",
        success: false,
      });
    }
    user = await User.create({
      email,
      password: await bcrypt.hash(password, 10),
      name,
      phone,
      role,
      profileimage
    });
  } else {
    if (
      !email ||
      !password ||
      !name ||
      !phone ||
      !businessName ||
      !businessDescription ||
      !profileimage
    ) {
      return res.status(400).send({
        message: "Please provide all fields",
        success: false,
      });
    }
    user = await User.create({
      email,
      password: await bcrypt.hash(password, 10),
      name,
      phone,
      role,
      businessName,
      businessDescription,
      profileimage
    });
  }

  const accessToken = jwt.sign(
    { 
      id: user._id,
      role: user.role 
    },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  const refreshToken = jwt.sign(
    { 
      id: user._id,
      role: user.role 
    },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );

  return res.status(201).send({
    message: "Registration successful",
    success: true,
    accessToken,
    refreshToken,
    user: {
      _id: user._id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role,
      businessName: user.businessName,
      businessDescription: user.businessDescription,
      profileimage: user.profileimage,
    },
  });
});

//REFRESH TOKEN
const refreshToken = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(401).json({
      message: "Refresh token is required",
      success: false,
    });
  }

  try {
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const user = await User.findById(decoded.id);

    if (!user) {
      return res.status(401).json({
        message: "User not found",
        success: false,
      });
    }

    const accessToken = jwt.sign(
      { 
        id: user._id,
        role: user.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    return res.status(200).json({
      success: true,
      accessToken,
    });
  } catch (error) {
    return res.status(401).json({
      message: "Invalid refresh token",
      success: false,
    });
  }
});

//LIST ALL REGISTERED VENDORS
const exploreUsers = asyncHandler(async (req, res) => {
  // Additional check to ensure only customers can explore vendors
  if (req.user.role !== "customer") {
    return res.status(403).json({
      message: "Only customers can explore vendors",
      success: false,
    });
  }

  const vendors = await User.find({role:"vendor"}).select("-password");
  res.status(200).json({
    success: true,
    vendors,
  });
});

//SIGNOUT
const signOut = asyncHandler(async (req, res) => {
  res.cookie("token", "", {
    httpOnly: true,
    expires: new Date(0),
  });
  res.cookie("refreshToken", "", {
    httpOnly: true,
    expires: new Date(0),
  });

  return res
    .status(200)
    .json({ message: "User logged out successfully", success: true });
});

//DELETE PROFILE
const deleteProfile = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  const user = await User.findById(userId);

  if (!user) {
    return res.status(404).json({ 
      message: "User not found", 
      success: false 
    });
  }

  // Additional check to ensure users can only delete their own profile
  if (user._id.toString() !== userId.toString()) {
    return res.status(403).json({ 
      message: "You can only delete your own profile", 
      success: false 
    });
  }

  await user.deleteOne();

  return res
    .status(200)
    .json({ 
      message: "Profile deleted successfully", 
      success: true 
    });
});

//GET USER DETAILS
const userDetails = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  const user = await User.findById(userId).select("-password");

  if (!user) {
    return res.status(404).json({ 
      message: "User not found", 
      success: false 
    });
  }

  // Additional check to ensure users can only access their own details
  if (user._id.toString() !== userId.toString()) {
    return res.status(403).json({ 
      message: "You can only access your own details", 
      success: false 
    });
  }

  return res.status(200).json({
    success: true,
    user,
  });
});

export { 
  login, 
  register, 
  exploreUsers, 
  signOut, 
  deleteProfile,
  userDetails,
  refreshToken 
};
