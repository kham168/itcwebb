import { dbExecution } from "../../config/dbConfig.js";
 

export const query_village_dataall = async (req, res) => { // done
 
  try {
    const query = `SELECT id, village,arean FROM public.tbprovince order by id asc limit 25`;
    const resultSingle = await dbExecution(query, []);
    console.log("Query result:", resultSingle?.rows);
    return res.json(resultSingle?.rows);
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const query_village_dataone = async (req, res) => { // done
   const id=req.body.id;
  try {
    const query = `SELECT id, village,arean FROM public.tbvillage where id='${id}'`;
    const resultSingle = await dbExecution(query, []);
    console.log("Query result:", resultSingle?.rows);
    return res.json(resultSingle?.rows);
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const insert_village_data = async (req, res) => { // done yet 90%
  const {id,village,arean}=req.body;
  try {
    const query = `INSERT INTO public.tbvillage(id, village, arean)VALUES ('${id}', '${village}', '${arean}');`;
    const resultSingle = await dbExecution(query, []);
    console.log("Query result:", resultSingle?.rows);
    return res.json(resultSingle?.rows);
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const update_village_data = async (req, res) => { // done
  
   const {id,village,arean}=req.body;

  try {
    const query = `UPDATE public.tbvillage SET village='${village}', arean='${arean}' WHERE id='${id}'`;
    const resultSingle = await dbExecution(query, []);
    console.log("Query result:", resultSingle?.rows);
    return res.json(resultSingle?.rows);
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};
