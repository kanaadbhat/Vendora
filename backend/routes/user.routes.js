import { Router } from 'express';
import { 
  login, 
  register, 
  exploreUsers, 
  signOut, 
  deleteProfile,
  fetchUserRole,
  refreshToken 
} from '../controllers/user.controller.js';
import protect from "../middleware/auth.middleware.js";

const router = Router();

// Auth routes
router.route('/login').post(login);
router.route('/register').post(register);
router.route('/logout').post(signOut);
router.route('/refresh-token').post(refreshToken);

// Protected routes
router.route('/details').get(protect, fetchUserRole);
router.route('/explore').get(protect, exploreUsers);
router.route('/delete').delete(protect, deleteProfile);

export default router;