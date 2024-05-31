import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import * as dotenv from 'dotenv';
import { genAccessJWT, genRefreshJWT } from '../../utils/jwtHelper.js';
import { dbExecution } from '../../config/dbConfig.js';
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const path2Private_key = path.join(__dirname,"..","..","key","private.key");
const PRIVATE_KEY = fs.readFileSync(path2Private_key, 'utf8');

export const refreshToken = async(req, res) => {
    const cookie = req?.cookies;

    if(!cookie || !cookie?.id_k) return res.status(401).send({resultCode: 401, message: `Unauthenticated`});

    const token = cookie?.id_k;
 
    try 
    {
        const objToken = await dbExecution(`SELECT * FROM tblrefreshtoken a WHERE a."RefreshToken"=$1`,[token]);

        if(!objToken || objToken?.rowCount < 1)
        {
            jwt?.verify(token, PRIVATE_KEY,{algorithms: "RS256"}, async(err, decoded) => {
                if(err)
                {
                    if(err?.name === 'TokenExpiredError')
                    {
                        return res.status(401).json({resultCode: 401, message: `Unauthenticated`});
                    }
                    else
                    {
                        return res.status(403).json({resultCode: 403, message: `Forbidden /${err?.name}`});
                    }
                }
                
                await dbExecution(`DELETE FROM tblrefreshtoken a WHERE a."UserID"=$1`,[decoded?.ID]);


                return res.status(401).json({resultCode: 401,message: "Unauthenticated",});
            });
        }
        else
        {
            await dbExecution(`DELETE FROM tblrefreshtoken a WHERE a."UserID"=$1 AND a."RefreshToken"=$2 `, [objToken?.rows[0]?.UserID, token]);

            jwt?.verify(token, PRIVATE_KEY, {algorithms: "RS256"}, async(err, decoded) => {
                if(err) 
                {
                    if(err?.name === 'TokenExpiredError')
                    {
                        return res.status(401).json({resultCode: 401, message: `Unauthenticated`});
                    }
                    else
                    {
                        return res.status(403).json({resultCode: 403, message: `Forbidden /${err?.name}`});
                    }
                }

                const accessToken = genAccessJWT({
                    ID: decoded?.ID,
                    EmpID: decoded?.EmpID,
                    UserName: decoded?.UserName,
                    Role: decoded?.Role,
                    UserLocation: decoded?.UserLocation
                });

                const refreshToken = genRefreshJWT({
                    ID: decoded?.ID,
                    EmpID: decoded?.EmpID,
                    UserName: decoded?.UserName,
                    Role: decoded?.Role,
                    UserLocation: decoded?.UserLocation
                });


                await dbExecution(`INSERT INTO tblrefreshtoken("UserID", "RefreshToken") VALUES($1, $2)`,[decoded?.ID, refreshToken]);

                res?.cookie('id_k', refreshToken, {
                    httpOnly: true,
                    secure: false,
                    sameSite: "Strict",
                    maxAge: 24 * 60 * 60 * 100
                });

                return res.status(200).send({
                    resultCode: 200, 
                    message: 'Operaction success', 
                    accessKey: accessToken, 
                    detail: {
                        ID: decoded?.ID,
                        UserLocation: decoded?.UserLocation,
                        Username: decoded?.UserName,
                        EmpID: decoded?.EmpID,
                        Role: decoded?.Role === 2 ? "User" : user?.Role === 1 ? "Administrator" : "User",
                        Status: decoded?.Status === 0 ? "Normal" : "Locked",
                        Updateby: decoded?.Updateby,
                        Flag: decoded?.Flag === 1 ? "Active" : "Inactive",
                        Updated_at: decoded?.Updated_at
                    }
                });
            });
        }
    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }

}
