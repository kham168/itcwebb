import Router from "express";
import { refreshToken } from '../../controllers/auth/refreshToken.js';

const route = Router();

route.get('/', refreshToken);

export default route;