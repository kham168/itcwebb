import { dbExecution } from "../../config/dbConfig.js";
 
export const query_house_dataall = async (req, res) => {   // done
  
  try {
    const query = `SELECT h.id, housearean, landarean, price, contactnumber, locationurl, status, moredetail, createdate,view_number, p.province, d.district,
    v.arean,v.village,i.houseurl
    FROM public.tbhouse h inner join public.tbprovince p on p.id=h.provinceid  inner join public.tbdistrict d on d.id=h.districtid
    inner join public.tbvillage v on v.id=h.villageid inner join public.tbhouseimage i on i.id=h.id
     order by createdate desc limit 50`;
    const resultSingle = await dbExecution(query, []);
    if (resultSingle) {
      res.status(200).send({
        status: true,
        message: "query data success",
        data: resultSingle?.rows,
      });
    } else {
      res.status(400).send({
        status: false,
        message: "query data fail",
        data: resultSingle?.rows,
      });
    }
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const query_house_dataone = async (req, res) => {    // done
  const id =req.body.id;
  try {
    const query = `SELECT h.id, housearean, landarean, price, contactnumber, locationurl, status, moredetail, createdate,view_number, p.province, d.district,
    v.arean,v.village,i.houseurl
    FROM public.tbhouse h inner join public.tbprovince p on p.id=h.provinceid  inner join public.tbdistrict d on d.id=h.districtid
    inner join public.tbvillage v on v.id=h.villageid inner join public.tbhouseimage i on i.id=h.id
     where h.id=$1`;
    const resultSingle = await dbExecution(query, [id]);
    if (resultSingle) {
      res.status(200).send({
        status: true,
        message: "query data success",
        data: resultSingle?.rows,
      });
    } else {
      res.status(400).send({
        status: false,
        message: "query data fail",
        data: resultSingle?.rows,
      });
    }
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};
 
export const query_house_data_by_district_or_arean_or_village = async (req, res) => {   // done
  const {province,district, arean, village} =req.body;
  try {
    const query = `SELECT h.id, housearean, landarean, price, contactnumber, locationurl, status, moredetail, createdate,view_number, p.province, d.district,
    v.arean,v.village,i.houseurl
    FROM public.tbhouse h inner join public.tbprovince p on p.id=h.provinceid  inner join public.tbdistrict d on d.id=h.districtid
    inner join public.tbvillage v on v.id=h.villageid inner join public.tbhouseimage i on i.id=h.id
     where p.province Ilike '%$1%' or d.district Ilike '%$2%' or v.arean Ilike '%$3%' or v.village Ilike '%$4%' order by createdate desc limit 25`;
    let values=[province,district, arean, village];
    const resultSingle = await dbExecution(query, values);
 
    if (resultSingle) {
      res.status(200).send({
        status: true,
        message: "query data success",
        data: resultSingle?.rows,
      });
    } else {
      res.status(400).send({
        status: false,
        message: "query data fail",
        data: resultSingle?.rows,
      });
    }

  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
}; 
  

export const insert_house_data = async (req, res) => { 
        
const data = req.body; 
  const {id, houseside, landside, price, contactnumber, locationurl, moredetail, provinceid, districtid, villageid}=req.body;
   
   if(req.file){
   data.file= req.file.filename
    } 
    
  try {
 
   const values_image = `INSERT INTO public.tbhouseimage( id, houseurl) VALUES ($1, $2)`;
   let values_i =[id,data.file];
   const resultSingle_image = await dbExecution(values_image, values_i);
     
    const query = `INSERT INTO public.tbhouse(
      id, housearean, landarean, price, contactnumber, locationurl, status, moredetail, createdate, provinceid, districtid, villageid,view_number)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) RETURNING *`;
      let values=[id, houseside, landside, price, contactnumber, locationurl,'1', moredetail, 'NOW()', provinceid, districtid, villageid,'9'];
      const resultSingle = await dbExecution(query, values);
   
    if (resultSingle && resultSingle.rowCount > 0) {
      return res.status(200).send({
        status: true,
        message: "insert data successfull",
        data: resultSingle?.rows,
      });

    } else {
      return res.status(400).send({
        status: false,
        message: "insert data fail",
        data: null,
      });
    }
    
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
}; 
  
export const update_active_status_house_data = async (req, res) => {     // done
   const {id, status}=req.body;
  try {
    const query = `UPDATE public.tbhouse SET status=$1 WHERE id=$2 RETURNING *`;
    let values=[status,id];
    const resultSingle = await dbExecution(query, values);
    if (resultSingle && resultSingle.rowCount > 0) {
      return res.status(200).send({
        status: true,
        message: "updadte data successfull",
        data: resultSingle?.rows,
      });
    } else {
      return res.status(400).send({
        status: false,
        message: "updadte data fail",
        data: null,
      });
    }

  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const update_price_house_data = async (req, res) => {    // done

  const {id,price}=req.body;

  try {
    const query = `UPDATE public.tbhouse SET  price=$1 WHERE id=$2 RETURNING *`;
    let values =[price,id];
    const resultSingle = await dbExecution(query, values);
    if (resultSingle && resultSingle.rowCount > 0) {
      return res.status(200).send({
        status: true,
        message: "updadte data successfull",
        data: resultSingle?.rows,
      });
    } else {
      return res.status(400).send({
        status: false,
        message: "updadte data fail",
        data: null,
      });
    }

  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const update_location_and_detail_house_data = async (req, res) => {    // done
  const {id,number,new_link,detail}=req.body;
  try {
    const query = `UPDATE public.tbhouse SET contactnumber=$1, locationurl=$2, moredetail=$3 WHERE id=$4 RETURNING *`;
  let values =[number,new_link,detail,id];
    const resultSingle = await dbExecution(query, values);
    if (resultSingle && resultSingle.rowCount > 0) {
      return res.status(200).send({
        status: true,
        message: "updadte data successfull",
        data: resultSingle?.rows,
      });
    } else {
      return res.status(400).send({
        status: false,
        message: "updadte data fail",
        data: null,
      });
    }

  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const update_side_of_land_and_house_data = async (req, res) => {     // done
  const {id,houseside,landside}=req.body;
  try {
    const query = `UPDATE public.tbhouse SET housearean=$1, landarean=$2 WHERE id=$3 RETURNING *`;
   let values =[houseside,landside,id];
    const resultSingle = await dbExecution(query, values);
    if (resultSingle && resultSingle.rowCount > 0) {
      return res.status(200).send({
        status: true,
        message: "updadte data successfull",
        data: resultSingle?.rows,
      });
    } else {
      return res.status(400).send({
        status: false,
        message: "updadte data fail",
        data: null,
      });
    }
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};

export const update_view_number_of_id = async (req, res) => {  // done
  const id=req.body.id;
  try {

    const query_v = `SELECT view_number FROM public.tbhouse where id=$1`;
 
    const result = await dbExecution(query_v, [id]);
    let view_number = result.rows[0].view_number; 
    view_number +=1;

    const query = `UPDATE public.tbhouse SET view_number=$1 WHERE id=$2 RETURNING *`;
    let values =[view_number,id];
    const resultSingle = await dbExecution(query, values);
     
    if (resultSingle && resultSingle.rowCount > 0) {
      return res.status(200).send({
        status: true,
        message: "updadte data successfull",
        data: resultSingle?.rows,
      });
    } else {
      return res.status(400).send({
        status: false,
        message: "updadte data fail",
        data: null,
      });
    }
  
  } catch (error) {
    console.error("Error in testdda:", error);
    res.status(500).send("Internal Server Error");
  }
};
