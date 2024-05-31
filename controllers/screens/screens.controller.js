import { customDate } from "../../utils/customDateFormats.js";
import { dbExecution } from "../../config/dbConfig.js";

export const readScreen = async(req, res) => {
    try 
    {
        const objScreens = await dbExecution(`SELECT * FROM fn_menu_dql(p_userid :=$1, p_userlocation :=$2, p_updateby := $3, p_role :=$4,p_action :=$5)`,[req?.ID,req?.UserLocation,req?.UserName,req?.Role,'UserID']);
        
        if(!objScreens || objScreens?.rowCount < 1)
        {
            console.log(`=>${customDate(new Date())?.formating?.yyyy_dash_MM_dash_dd_space_h24_mm_ss}\tNot found any menu for userID = ${req?.ID}`);
            return res.status(404).json({resultCode: 404, message: 'This user has no permission for any menu.'});
        }

        return res.status(200).json({resultCode: 200, message: 'Successfully!', detail: objScreens?.rows || null });

    } 
    catch (error) 
    {
        console.error('==>> ',error);
        return res.status(500).send('Internal Server Error');
    }
}