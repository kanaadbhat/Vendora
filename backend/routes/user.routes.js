import { Router } from 'express';
import { 
  login, 
  register, 
  exploreUsers, 
  signOut, 
  deleteProfile,
  userDetails,
  refreshToken 
} from '../controllers/user.controller.js';
import protect from "../middleware/auth.middleware.js";
import { isCustomer, isVendor } from "../middleware/role.middleware.js";

const router = Router();

// Auth routes (public)
router.route('/login').post(login);
router.route('/register').post(register);
router.route('/logout').post(signOut);
router.route('/refresh-token').post(refreshToken);

// Protected routes with role-based access
router.route('/details').get(protect, userDetails); // Both customers and vendors can access their own details
router.route('/explore').get(protect, isCustomer, exploreUsers); // Only customers can explore vendors
router.route('/delete').delete(protect, deleteProfile); // Both can delete their own profile

export default router;