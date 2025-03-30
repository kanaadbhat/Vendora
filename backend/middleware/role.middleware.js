import { asyncHandler } from "../utils/asyncHandler.js";

// Middleware to check if user has required role
const checkRole = (roles) => {
  return asyncHandler(async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        message: "Unauthorized: User not authenticated", 
        success: false 
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: "Forbidden: You don't have permission to access this resource", 
        success: false 
      });
    }

    next();
  });
};

// Specific role checkers
const isCustomer = checkRole(["customer"]);
const isVendor = checkRole(["vendor"]);
const isAdmin = checkRole(["admin"]);

export { checkRole, isCustomer, isVendor, isAdmin }; 