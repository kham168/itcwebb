import jwt from "jsonwebtoken";
import fs from 'fs';
import path from "path";
import { fileURLToPath } from "url";
import * as dotenv from 'dotenv';
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const path2PublicKey = path.join(__dirname,"..","key","public.key");

const PUBLIC_KEY = fs.readFileSync(path2PublicKey,"utf8"); 

export const verifyJWT = (req, res, next) => {
    const auth_key = req?.headers?.authorization;
    
    if(!auth_key || !auth_key?.startsWith("Bearer "))
    {
        console.log('unauthorized => ',req?.headers);
        return res.status(401).json({resultCode: 401, message: "Unauthorized"});
    }
    
    const token = auth_key?.split(" ")[1];

    jwt?.verify(token, PUBLIC_KEY, {
        algorithms: "RS256",
    }, 
    (err, plainCode)=> {
        if(err)
        {
            if(err?.name === 'TokenExpiredError')
            {
                console.log(`token is expired`);
                return res.status(401).json({resultCode: 401, message: "Session is expired"});
            }
            else
            {
                console.log(`${req?.headers}\t Forbidden on jwt decode error`);
                return res.status(403).json({resultCode: 403, message: "Forbidden"});
            }
        }
        
        req.ID = plainCode?.ID;
        req.EmpID = plainCode?.EmpID;
        req.UserName = plainCode?.UserName;
        req.Role = plainCode?.Role;
        req.UserLocation = plainCode?.UserLocation;

        next();
        
    });

}