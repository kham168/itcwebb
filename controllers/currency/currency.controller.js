import { dbExecution } from "../../config/dbConfig.js";
import { customDate } from "../../utils/customDateFormats.js";
import { getIntFlag } from '../../utils/subFunction.js';

const readSingle = async(ID,LocationID, UserLocation, Updateby,Role)=>{

    if(!ID || !LocationID || !Updateby || !UserLocation || !Role) return false;
    
    try 
    {
        const resultSingle = await dbExecution(`SELECT*FROM public.fn_currency_dql (p_id :=$1,p_locationid :=$2,p_userlocation :=$3,p_updateby :=$4,p_role :=$5,p_action :=$6)`,[ID, LocationID, UserLocation, Updateby,Role,'ONE']);
        
        if(!resultSingle || resultSingle?.rowCount < 1)
        {
            console.log(`resultSingle => ${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNot found data`,resultSingle);
            return false;
        }

        resultSingle?.rows.forEach(row => {
            row.QR = row?.QR?.split('|');
        });

        return resultSingle;
    } 
    catch (error) 
    {
        console.error('readSingle ==>> ',error);
        return false;
    }
}

export const createCurrency = async(req, res) => {
    if(!req?.body?.ComputerIP || !req?.body?.Currency || !req?.body?.Symbol || !req?.body?.LocationID)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields not supplied.' });
    }
    
    try 
    {
        const inputArr = [
            req?.body?.ComputerIP || null,
            req?.body?.Currency || 0,
            req?.body?.Symbol || 0,
            req?.body?.Note || null,
            String(getIntFlag(req?.body?.Flag)),
            req?.body?.LocationID || null,
            req?.UserLocation,
            req?.UserName,
            req.Role,
            "I"
        ];
        
        const result = await dbExecution(`SELECT public.fn_Currency_dml(p_computerip :=$1 ,p_currency :=$2 ,p_symbol :=$3, p_note :=$4,p_flag :=$5,p_locationid :=$6,p_userlocation :=$7,p_updateby :=$8, p_role :=$9, p_action := $10)`, inputArr);
        
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

export const updateCurrency = async(req, res) => {
    
    if(!req?.body?.ID || !req?.body?.LocationID)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields not supplied.' });
    }
    
    try 
    {
        //readOld data
        const resultSingle = await readSingle(req?.body?.ID, req?.body?.LocationID,req?.UserLocation, req?.UserName,req?.Role);

        if(!resultSingle || resultSingle?.rows < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not update data`);
            return res.status(404).json({resultCode: 404, message: 'Not found data to update.'});
        }

        const inputArr = [
            req?.body?.ID,
            req?.body?.ComputerIP || null,
            req?.body?.Currency || 0,
            req?.body?.Symbol || 0,
            req?.body?.Note || null,
            String(getIntFlag(req?.body?.Flag)),
            req?.body?.LocationID || null,
            req?.UserLocation,
            req?.UserName,
            req.Role,
            "U"
        ];
        
        const result = await dbExecution(`SELECT public.fn_Currency_dml(p_id :=$1,p_computerip :=$2 ,p_currency :=$3 ,p_symbol :=$4, p_note :=$5,p_flag :=$6,p_locationid :=$7,p_userlocation :=$8,p_updateby :=$9, p_role :=$10, p_action := $11)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not update data`);
            return res.status(404).json({resultCode: 404, message: 'Update data failed.'});
        }

        return res.status(200).json({resultCode: 200, message: 'Update Successfully!'});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}

export const deleteCurrency = async(req, res) => {
    
    if(!req?.body?.ID || !req?.body?.LocationID || !req?.body?.ComputerIP)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields are not supplied.' });
    }

    try 
    {
        //readOld data
        const resultSingle = await readSingle(req?.body?.ID, req?.body?.LocationID,req?.UserLocation, req?.UserName, req?.Role);

        if(!resultSingle)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNot found data to delete`);
            return res.status(404).json({resultCode: 404, message: 'Not found data to delete.'});
        }

        const inputArr = [
            Number(req?.body?.ID),
            req?.body?.ComputerIP,
            req?.UserName,
            req?.body?.LocationID,
            req?.UserLocation,
            req?.Role,
            "D"
        ];

        const result = await dbExecution(`SELECT public.fn_Currency_dml (p_id :=$1,p_computerip :=$2,p_updateby :=$3,p_locationid :=$4,p_userlocation :=$5,p_role := $6, p_action :=$7)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not delete data`);
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

export const changeCurrencyStatus = async(req, res) => {
    
    if(req?.body?.Flag > 1 || req?.body?.Flag < 0)
    {
        return res.status(400).json({resultCode: 400, message: 'Flag not supplied correctly.'});
    }

    if(!req?.body?.ID || !req?.body?.LocationID || !req?.body?.ComputerIP)
    {
        return res.status(400).json({resultCode: 400, message: 'Fields are not supplied.' });
    }

    try 
    {
        //readOld data
        const resultSingle = await readSingle(req?.body?.ID, req?.body?.LocationID,req?.UserLocation, req?.UserName,req?.Role);

        if(!resultSingle)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not save data`);
            return res.status(404).json({resultCode: 404, message: 'OMG! No data found !.'});
        }

        const inputArr = [
            Number(req?.body?.ID),
            req?.body?.ComputerIP,
            String(getIntFlag(req?.body?.Flag)),
            req?.UserName,
            req?.body?.LocationID,
            req?.UserLocation,
            req?.Role,
            "F"
        ];

        const result = await dbExecution(`select public.fn_Currency_dml (p_id :=$1,p_computerip :=$2,p_flag := $3,p_updateby :=$4,p_locationid :=$5,p_userlocation :=$6,p_role := $7, p_action :=$8)`, inputArr);
        
        if(!result || result?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tCan not change data`);
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

export const readCurrency = async(req, res) => {
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
            sql = `SELECT*FROM public.fn_Currency_dql (p_updateby :=$1,p_role :=$2,p_userlocation :=$3,p_action :=$4)`;
            
            inputArr = [
                req?.UserName,
                req?.Role,
                req?.UserLocation,
                req?.body?.Action
            ];
        }
        if(req?.body?.Action === "PARTIAL")
        {
            sql = `SELECT*FROM public.fn_Currency_dql(p_page_number :=$1,p_items_per_page :=$2,p_updateby :=$3,p_role :=$4,p_userlocation :=$5,p_action :=$6)`;
            
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
            sql = `SELECT*FROM public.fn_Currency_dql(p_id :=$1,p_updateby :=$2,p_role :=$3,p_userlocation :=$4,p_action :=$5)`;
            
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

            sql = `SELECT*FROM public.fn_Currency_dql(p_page_number :=$1,p_items_per_page :=$2, p_keyword :=$3,p_updateby :=$4,p_role :=$5,p_userlocation :=$6,p_action :=$7)`;
            
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
        console.log(sql, inputArr)
        const result = await dbExecution(sql, inputArr);
        
        if(result?.rowCount < 1)
        {
            console.log(`read shift detail =>${customDate (new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNo data found!`, result?.rows);
            return res.status(404).json({resultCode: 404, message: 'No data found!'});
        }

        result?.rows.forEach(row => {
            row.QR = row?.QR?.split('|');
        });
        
        return res.status(200).json({resultCode: 200, message: 'Successfully!', detail: result?.rows});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}