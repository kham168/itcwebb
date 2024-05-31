import { dbExecution } from "../../config/dbConfig.js";
import { customDate } from "../../utils/customDateFormats.js";
import { getIntFlag } from '../../utils/subFunction.js';

export const readTaxType = async(req, res) => {
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
            sql = `SELECT*FROM public.fn_taxtype_dql(p_updateby :=$1,p_role :=$2,p_locationid :=$3,p_userlocation :=$4,p_action :=$5)`;
            
            inputArr = [
                req?.UserName,
                req?.Role,
                req?.body?.LocationID,
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
            sql = `SELECT*FROM public.fn_taxtype_dql(p_id :=$1, p_updateby :=$2,p_role :=$3,p_locationid :=$4,p_userlocation :=$5,p_action :=$6)`;
            
            inputArr = [
                req?.body?.ID,
                req?.UserName,
                req?.Role,
                req?.body?.LocationID,
                req?.UserLocation,
                req?.body?.Action
            ];
        }
        
        const result = await dbExecution(sql, inputArr);
        
        if(result?.rowCount < 1)
        {
            console.log(`read tax type detail =>${customDate (new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNo data found!`, result?.rows);
            return res.status(404).json({resultCode: 404, message: 'No data found!'});
        }
        
        return res.status(200).json({resultCode: 200, message: 'Successfully!', detail: result?.rows});

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}