
import bcrypt from 'bcrypt';
import { customDate } from '../../utils/customDateFormats.js';
import { genAccessJWT, genRefreshJWT } from '../../utils/jwtHelper.js';
import { dbExecution } from '../../config/dbConfig.js';


export const Login = async(req, res) => {

    const {Username, Password} = req?.body;
    try 
    {
        const objUsers = await dbExecution('SELECT a."ID",b."EmpID",a."UserName",a."Password",a."Role",a."Status",a."RetryCount",a."Flag",a."LocationID",a."Updateby",a."Updated_at" FROM tbluser a JOIN tblemployee b ON a."EmpID" = b."ID" AND a."Flag" = b."Flag" WHERE a."UserName"=$1 AND a."Flag"=$2',[Username,1]);

        if(!objUsers || objUsers?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNot found user for`,req?.body);
            return res.status(404).json({resultCode: 404, message: 'No user found'});
        }

        for(const user of objUsers?.rows)
        {
            if(user?.UserName === Username && bcrypt?.compareSync(Password, user?.Password))
            {
                if(user?.Status !== 0 || user?.RetryCount > 5)
                {
                    console.log(`===> ${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\t This user is locked`, req?.body);
                    
                    await dbExecution(`UPDATE tbluser SET "Status" = CASE WHEN ("RetryCount" + 1) > 5 THEN 1 ELSE 0 END, "RetryCount" = "RetryCount" + 1, "Updated_at"=now() WHERE "ID"=$1`, [user?.ID]);

                    return res.status(403).json({resultCode: 403, message: 'This user is locked. Please, wait for automaticaly reset after 24hrs'});
                }

                const accessToken = genAccessJWT({
                    ID: user?.ID,
                    EmpID: user?.EmpID,
                    UserName: user?.UserName,
                    Role: user?.Role,
                    UserLocation: user?.LocationID
                });

                const refreshToken = genRefreshJWT({
                    ID: user?.ID,
                    EmpID: user?.EmpID,
                    UserName: user?.UserName,
                    Role: user?.Role,
                    UserLocation: user?.LocationID
                })
                
                await dbExecution(`UPDATE tbluser SET "Status" = 0, "RetryCount" = 0, "Updated_at"=now() WHERE "ID"=$1`, [user?.ID]);

                await dbExecution(`DELETE FROM tblrefreshtoken a WHERE a."UserID"=$1 `, [user?.ID]);

                await dbExecution(`INSERT INTO tblrefreshtoken("UserID", "RefreshToken") VALUES($1, $2)`,[user?.ID, refreshToken]);

                await dbExecution(`INSERT INTO tbluseractivity("Action","UserID","Function","Note") VALUES($1,$2,$3,$4)`,['Login',user?.ID, "Login","Record by system"]);


                res?.cookie('id_k', refreshToken, {
                    httpOnly: true,
                    secure: false,
                    sameSite: "Strict",
                    maxAge: 24 * 60 * 60 * 1000
                });
                
                return res.status(200).json({
                    resultCode: 200, 
                    message: 'Login successfully!', 
                    accessKey: accessToken, 
                    detail: { 
                        ID: user?.ID,
                        Username: user?.UserName,
                        UserLocation: user?.LocationID,
                        EmpID: user?.EmpID,
                        Role: user?.Role === 2 ? "User" : user?.Role === 1 ? "Administrator" : "User",
                        Status: user?.Status === 0 ? "Normal" : "Locked",
                        Updateby: user?.Updateby,
                        Flag: user?.Flag === 1 ? "Active" : "Inactive",
                        Updated_at: user?.Updated_at
                    }
                });
            }
            else if(objUsers?.rowCount === 1)
            {
                await dbExecution(`UPDATE tbluser SET "Status" = CASE WHEN ("RetryCount" + 1) > 5 THEN 1 ELSE 0 END, "RetryCount" = "RetryCount" + 1, "Updated_at"=now() WHERE "UserName"=$1`,[Username]);
            }
        }
        return res.status(404).json({resultCode: 404, message: 'Username or password is incorrect'});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}

export const resetPassword = async(req, res) => {
    try
    {
        const userId = req?.params?.id;
        const { passwordNew, confirmPassword } = req?.body;

        if(!userId)
        {
            console.log(`resetPassword => not found user ID to reset password`);
            return res?.status(400).json({resultCode: 400, message: 'Field is not supplied'});
        }

        if(passwordNew?.length < 6)
        {
            console.log(`resetPassword character length < 6`);
            return res.status(400).json({resultCode: 400, message: `Password must be 6 or more characters.`});
        }

        if(confirmPassword !== passwordNew)
        {
            console.log(`Password is not matched`);
            return res.status(400).json({resultCode: 400, message: `Password does not matched`});
        }
        
        const objUsers = await dbExecution('SELECT * FROM tbluser a JOIN tblemployee b ON a."EmpID" = b."ID" AND b."Flag" = $1 WHERE a."ID"=$2',[1, userId]);

        if(!objUsers || objUsers?.rowCount !== 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNot found user for userID = ${userId}`);
            return res.status(404).json({resultCode: 404, message: 'No user found'});
        }

        if(objUsers?.rows[0]?.Flag !== 1)
        {
            console.log(`ResetPassword with inactive username`, objUsers?.rows);
            return res.status(400).json({resultCode: 400, messaeg: 'Reset password failed. This user is inactive.'});
        }

        bcrypt?.genSalt(10, (err, salt) => {
            if(err)
            {
                console.log("ResetPassword failed on gen salt ==>> ", err);
                return res.status(400).json({resultCode: 400, message: `Authentication went wrong`});
            }

            bcrypt.hash(passwordNew, salt, async(_err, hashCode) => {
                if(_err)
                {
                    console.log("ResetPassword failed on hasing password ==>> ", _err);
                    return res.status(400).json({resultCode: 400, message: `Authentication went wrong`});
                }

                const resultResetPWD = await dbExecution(`UPDATE tbluser SET "Password"='${hashCode}', "Status" = 0, "RetryCount" = 0, "Updated_at"=now() WHERE "ID"=$1`,[userId]);

                if(resultResetPWD?.rowCount < 1)
                {
                    console.log("ResetPassword failed in query ===> ", userId);
                    return res.status(400).json({resultCode: 400, message: 'Not found user to reset password'});
                }

                return res.status(200).json({resultCode: 200, message: 'Reset password successfully!'});
            });
        });

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}