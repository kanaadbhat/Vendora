import {Router} from 'express';
import { login, register, exploreUsers,signOut ,deleteProfile} from '../controllers/user.controller.js';
import protect from "../middleware/auth.middleware.js";

const router = Router();
router.route('/signIn').post(login);
router.route('/signUp').post(register);
router.get('/exploreUsers', protect, exploreUsers);
router.post("/signOut", signOut);
router.delete("/deleteProfile", protect, deleteProfile);


export default router;