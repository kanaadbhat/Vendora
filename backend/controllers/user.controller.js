
import { User } from "../models/user.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import jwt from "jsonwebtoken";

//SIGNIN
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).send({
      message: "Please provide email and password",
      success: false,
    });
  }

  const user =await User.findOne({ email });

  if (!user || user.password !== password) {
    return res.status(400).send({
      message: "Incorrect email or password",
      success: false,
    });
  }

  const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET);

  res.cookie("token", token, {
    httpOnly: true,
    sameSite: "Strict",
  });

  return res.status(200).send({
    message: "Login successful",
    success: true,
    user,
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
  } = req.body;
  console.log(req.body);

  const check = await User.findOne({ email });
  if (check) {
    return res.status(400).send({
      message: "User already exists",
      success: false,
    });
  }

  if (role === "customer") {
    if (!email || !password || !name || !phone) {
      return res.status(400).send({
        message: "Please provide all fields",
        success: false,
      });
    }
    const user = await User.create({
      email,
      password,
      name,
      phone,
      role,
    });
    await user.save();
    return res.status(201).send({
      message: "Customer registered successfully",
      success: true,
    });
  } else {
    if (
      !email ||
      !password ||
      !name ||
      !phone ||
      !businessName ||
      !businessDescription
    ) {
      return res.status(400).send({
        message: "Please provide all fields",
        success: false,
      });
    }
    const user = await User.create({
      email,
      password,
      name,
      phone,
      role,
      businessName,
      businessDescription,
    });
    await user.save();
    return res.status(201).send({
      message: "Vendor registered successfully",
      success: true,
    });
  }
});

//LIST ALL REGISTERED VENDORS
const exploreUsers = asyncHandler(async (req, res) => {
  const vendors = await User.find({role:"vendor"}).select("-password");
  res.status(200).json({
    success: true,
    vendors,
  });
});

//SIGNOUT
const signOut = asyncHandler(async (req, res) => {
  res.cookie("jwt", "", {
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

  const user =
    await User.findById(userId);

  if (!user) {
    return res.status(404).json({ message: "User not found", success: false });
  }

  await user.deleteOne();

  return res
    .status(200)
    .json({ message: "Profile deleted successfully", success: true });
});

export { login, register, exploreUsers, signOut, deleteProfile };
