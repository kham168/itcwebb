import { dbExecution } from "../../config/dbConfig.js";
import { customDate } from "../../utils/customDateFormats.js";
import { accessBaseFilePath, deleteFiles } from "../../utils/multerHelper.js";
import { getIntFlag } from '../../utils/subFunction.js';

const readSingle = async(ID, UserLocation, Updateby)=>{
    
    if(!ID || !UserLocation || !Updateby) return false;
    
    try 
    {
        const resultSingle = await dbExecution(`SELECT*FROM public.fn_location_dql (p_id :=$1,p_userlocation :=$2,p_updateby :=$3,p_action :=$4)`,[ID, UserLocation, Updateby,'ONE']);
        
        if(!resultSingle || resultSingle?.rowCount < 1)
        {
            console.log(`resultSingle => ${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return false;
        }

        resultSingle?.rows.forEach(row => {
            row.Logo = row?.Logo?.split('|');
            row.Profile = row?.Profile?.split('|');
        });

        return resultSingle;
    } 
    catch (error) 
    {
        console.error('readSingle location ==>> ',error);
        return false;
    }
}

export const createLocation = async(req, res) => {
    
    if ((req.files['LocationLogo'] && req.files['LocationLogo'].length > 1) || (req.files['Profile'] && req.files['Profile'].length > 1)) 
    {
        return res.status(400).json({resultCode: 400, message: 'Too many files' });
    }
    if(req?.body?.Flag > 1 || req?.body?.Flag < 0)
    {
        return res.status(400).json({resultCode: 400, message: 'Flag not supplied correctly.'});
    }
    if(!req?.body?.ComputerIP || !req?.body?.Location)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields not supplied.' });
    }
    
    try 
    {
        const inputArr = [
            req?.body?.ComputerIP,
            req?.body?.Location,
            req?.body?.Tel1,
            req?.body?.Tel2,
            req?.body?.Mobile,
            req?.body?.Lat,
            req?.body?.Long,
            req?.body?.Address,
            req.files['LocationLogo'] ? req.files['LocationLogo'].map((file) => accessBaseFilePath(file?.filename, req?.path))?.join('|') : null,
            req.files['Profile'] ? req?.files['Profile'].map((file) => accessBaseFilePath(file?.filename, req?.path))?.join('|') : null,
            req?.body?.Note,
            String(getIntFlag(req?.body?.Flag)),
            req?.UserName,
            req?.UserLocation,
            req?.Role,
            "I"
           //req?.files["Profile"].map((file)=> accessBaseFilePath(file?.filename, req?.path))
           
        ];

        const result = await dbExecution(`select public.fn_location_dml (p_computerip := $1, p_location := $2,p_tel1 := $3, p_tel2 :=$4, p_mobile :=$5,p_lat :=$6,p_long :=$7,p_address := $8,p_logo :=$9,p_profile :=$10,p_note :=$11,p_flag := $12 ,p_updateby :=$13,p_userlocation :=$14,p_role :=$15,p_action := $16)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'Save data failed.'});
        }

        return res.status(200).json({resultCode: 200, message: 'Successfully!'});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}

export const updateLocation = async(req, res) => {
    if ((req.files['LocationLogo'] && req.files['LocationLogo'].length > 1) || (req.files['Profile'] && req.files['Profile'].length > 1)) 
    {
        return res.status(400).json({resultCode: 400, message: 'Too many files' });
    }
    if(!req?.body?.ComputerIP || !req?.body?.Location)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields not supplied.' });
    }
    if(req?.body?.Flag > 1 || req?.body?.Flag < 0)
    {
        return res.status(400).json({resultCode: 400, message: 'Flag not supplied correctly.'});
    }

    if(!req?.body?.ID)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields ID not supplied.' });
    }

    try 
    {
        //readOld data
        const resultSingle = await readSingle(req?.body?.ID, req?.UserLocation, req?.UserName);
        if(!resultSingle)
        {
            req.files['LocationLogo'] ? req.files['LocationLogo'].map((file) => deleteFiles(accessBaseFilePath(file?.filename, req?.path))) : null
            req.files['Profile'] ? req.files['Profile'].map((file) => deleteFiles(accessBaseFilePath(file?.filename, req?.path))) : null
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'Not found data to update.'});
        }

        const inputArr = [
            Number(req?.body?.ID),
            req?.body?.ComputerIP,
            req?.body?.Location || null,
            req?.body?.Tel1 || null,
            req?.body?.Tel2 || null,
            req?.body?.Mobile || null,
            req?.body?.Lat || null,
            req?.body?.Long || null,
            req?.body?.Address || null,
            req.files['LocationLogo'] ? req.files['LocationLogo'].map((file) => file.filename).join('|') : null,
            req.files['Profile'] ? req?.files['Profile'].map((file) => file?.filename).join('|') : null,
            req?.body?.Note || null,
            String(getIntFlag(req?.body?.Flag)),
            req?.UserName,
            req?.UserLocation,
            req?.Role,
            "U"
        ];

        const result = await dbExecution(`select public.fn_location_dml (p_id :=$1, p_computerip := $2, p_location := $3,p_tel1 := $4, p_tel2 :=$5, p_mobile :=$6,p_lat :=$7,p_long :=$8,p_address := $9,p_logo :=$10,p_profile :=$11,p_note :=$12,p_flag := $13 ,p_updateby :=$14,p_userlocation := $15,p_role :=$16,p_action := $17)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'Update data failed.'});
        }

        const removeImgProfile = resultSingle?.rows[0]?.Profile?.map((file) => deleteFiles(file));
        const removeImgLogo = resultSingle?.rows[0]?.Logo?.map((file) => deleteFiles(file));

        return res.status(200).json({resultCode: 200, message: 'Update Successfully!'});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }

}

export const deleteLocation = async(req, res) => {
    
    if(!req?.body?.ComputerIP)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields not supplied.'});
    }

    if(!req?.body?.ID)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields ID not supplied.' });
    }

    try 
    {
        //readOld data
        const resultSingle = await readSingle(req?.body?.ID, req?.UserLocation, req?.UserName);

        if(!resultSingle)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'Not found data to delete.'});
        }

        const inputArr = [
            Number(req?.body?.ID),
            req?.body?.ComputerIP,
            req?.UserName,
            req?.UserLocation,
            req?.Role,
            "D"
        ];

        const result = await dbExecution(`select public.fn_location_dml (p_id :=$1,p_computerip :=$2,p_updateby :=$3,p_userlocation :=$4,p_role := $5,p_action :=$6)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'Delete data failed.'});
        }
        return res.status(200).json({resultCode: 200, message: 'Delete Successfully!'});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}

export const changeLocationStatus = async(req, res) => {
    
    if(!req?.body?.ComputerIP || !String(req?.body?.Flag))
    {
        return res.status(400).json({resultCode: 400, message: 'Fields not supplied.'});
    }

    if(req?.body?.Flag > 1 || req?.body?.Flag < 0)
    {
        return res.status(400).json({resultCode: 400, message: 'Flag not supplied correctly.'});
    }

    if(!req?.body?.ID)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields ID not supplied.' });
    }

    try 
    {
        //readOld data
        const resultSingle = await readSingle(req?.body?.ID, req?.UserLocation, req?.UserName);

        if(!resultSingle)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'OMG! No data found !'});
        }

        const inputArr = [
            Number(req?.body?.ID),
            req?.body?.ComputerIP,
            String(getIntFlag(req?.body?.Flag)),
            req?.UserName,
            req?.UserLocation,
            req?.Role,
            "F"
        ];

        const result = await dbExecution(`select public.fn_location_dml (p_id :=$1,p_computerip :=$2,p_flag := $3,p_updateby :=$4,p_userlocation :=$5,p_role :=$6,p_action :=$7)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'Change status failed.'});
        }

        return res.status(200).json({resultCode: 200, message: 'Change status successfully!'});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}

export const readLocation = async(req, res) => {
    if(!req?.body?.Action)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields action is not supplied correctly.'});
    }

    try 
    {
        let inputArr = [];
        let sql = "";

        if(req?.body?.Action === "ALL")
        {
            sql = `SELECT*FROM public.fn_location_dql (p_updateby :=$1,p_role :=$2,p_userlocation :=$3,p_action :=$4)`;
            
            inputArr = [
                req?.UserName,
                req?.Role,
                req?.UserLocation,
                req?.body?.Action
            ];
        }
        if(req?.body?.Action === "PARTIAL")
        {
            sql = `SELECT*FROM public.fn_location_dql (p_page_number :=$1,p_items_per_page :=$2,p_updateby :=$3,p_role :=$4,p_userlocation :=$5,p_action :=$6)`;
            
            inputArr = [
                req?.body?.PageNo,
                req?.body?.PageSize,
                req?.UserName,
                req?.Role,
                req?.UserLocation,
                req?.body?.Action
            ];
        }
        else if(req?.body?.Action === "ONE")
        {
            if(!req?.body?.ID)
            {
                return res.status(400).json({resultCode: 400, message: 'Fields ID is not supplied.'});
            }

            sql = `SELECT*FROM public.fn_location_dql (p_id :=$1,p_updateby :=$2,p_role :=$3,p_userlocation :=$4,p_action :=$5)`;
            
            inputArr = [
                req?.body?.ID,
                req?.UserName,
                req?.Role,
                req?.UserLocation,
                req?.body?.Action
            ];
        }
        else if(req?.body?.Action === "SEARCH")
        {
            if(!req?.body?.Keyword)
            {
                return res.status(400).json({resultCode: 400, message: 'Fields Keyword is not supplied.'});
            }

            sql = `SELECT*FROM public.fn_location_dql (p_page_number :=$1,p_items_per_page :=$2, p_keyword :=$3,p_updateby :=$4,p_role :=$5,p_userlocation :=$6,p_action :=$7)`;
            
            inputArr = [
                req?.body?.PageNo,
                req?.body?.PageSize,
                req?.body?.Keyword,
                req?.UserName,
                req?.Role,
                req?.UserLocation,
                req?.body?.Action
            ];
        }

        const result = await dbExecution(sql, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`read location =>${customDate (new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNo data found!`, result?.rows);
            return res.status(404).json({resultCode: 404, message: 'No data found!'});
        }

        result?.rows.forEach(row => {
            row.Logo = row?.Logo?.split('|');
            row.Profile = row?.Profile?.split('|');
        });

        return res.status(200).json({resultCode: 200, message: 'Successfully!', detail: result?.rows});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}