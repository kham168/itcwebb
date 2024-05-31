import jwt from "jsonwebtoken";
import fs from 'fs';
import path from "path";
import { fileURLToPath } from "url";
import * as dotenv from 'dotenv';
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const path2PrivateKey = path.join(__dirname,"..","key","private.key");

const PRIVATE_KEY = fs.readFileSync(path2PrivateKey,"utf8");


export const genAccessJWT = (payload)=>{
    const accessOptions = {
        expiresIn: String(process.env.JWT_EXPIRY_ACCESS),
        algorithm: "RS256",
    }

    return jwt.sign(payload, PRIVATE_KEY, accessOptions);
}

export const genRefreshJWT = (payload) => {
    const accessOptions = {
        expiresIn: String(process.env.JTW_REFRESH_EXPIRY),
        algorithm: "RS256",
    }

    return jwt.sign(payload, PRIVATE_KEY, accessOptions);
}