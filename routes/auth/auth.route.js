import Router from "express";
import { verifyJWT } from '../../middleware/jwt.js';
import { Login, resetPassword } from '../../controllers/auth/auth.controller.js';

const route = Router();

route.post('/login', Login);
route.post('/reset-password-admin/id/:id', verifyJWT, resetPassword);

export default route;