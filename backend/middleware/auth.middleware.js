import jwt from "jsonwebtoken";
import {User} from "../models/user.model.js";
import {asyncHandler} from "../utils/asyncHandler.js";

const protect = asyncHandler(async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith("Bearer")) {
        try {
            token = req.headers.authorization.split(" ")[1]; 
            console.log("Token:",token);
            const decoded = jwt.verify(token, process.env.JWT_SECRET); 
            console.log("Decoded ID:", decoded.id);

            
            const  user = await User.findById(decoded.id).select("-password"); 
       

            if (!user) {
                return res.status(401).json({ message: "Unauthorized: User not found", success: false });
            }

            req.user = user; 
            next();
        } catch (error) {
            return res.status(401).json({ message: "Unauthorized: Invalid token", success: false });
        }
    } else {
        return res.status(401).json({ message: "Unauthorized: No token provided", success: false });
    }
});

export default protect;
