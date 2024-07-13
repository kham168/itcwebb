import { dbExecution } from "../../config/dbConfig.js";
 
export const query_land_dataall = async (req, res) => { // done
  
  try {
    const query = `SELECT l.id, area, price, contactnumber, locationurl, moredetail, status, createdate,view_number, 
    p.province,d.district,v.arean,v.village,i.imageurl
    FROM public.tbland l inner join public.tbprovince p on p.id=l.districtid
    inner join public.tbdistrict d on d.id=l.districtid inner join public.tbvillage v on v.id=l.villageid 
    inner join public.tblandimage i on i.id=l.id order by l.createdate desc limit 50`;
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

export const query_land_dataone = async (req, res) => {
 
   const id=req.body.id;
  try {
    const query = `SELECT l.id, area, price, contactnumber, locationurl, moredetail, status, createdate,view_number, 
    p.province,d.district,v.arean,v.village,i.imageurl
    FROM public.tbland l inner join public.tbprovince p on p.id=l.districtid
    inner join public.tbdistrict d on d.id=l.districtid inner join public.tbvillage v on v.id=l.villageid 
    inner join public.tblandimage i on i.id=l.id where l.id=$1`;
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
 
export const query_land_data_by_district_or_arean_or_village = async (req, res) => { // done

   const {province,district,arean,village}=req.body;
  try {

    const query = `SELECT l.id, area, price, contactnumber, locationurl, moredetail, status, createdate,view_number, 
    p.province,d.district,v.arean,v.village,i.imageurl
    FROM public.tbland l inner join public.tbprovince p on p.id=l.districtid
    inner join public.tbdistrict d on d.id=l.districtid inner join public.tbvillage v on v.id=l.villageid 
    inner join public.tblandimage i on i.id=l.id where p.province Ilike '%$1%' or d.district Ilike '%$2%' or v.arean Ilike '%$3%' or v.village Ilike '%$4%' order by createdate desc limit 50`;
    
    let values = [province,district,arean,village];
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
 
export const insert_land_data = async (req, res) => { 

  const data = req.body; 
 
  const {id, landside, price, contactnumber, locationurl, moredetail, provinceid, districtid, villageid}=req.body;

  if(req.file){

    data.file= req.file.filename

     }   
  try {

    const query_image = `INSERT INTO public.tblandimage(id, imageurl) VALUES ($1, $2) RETURNING *`;
    let values_image = [id,data.file];
    const resultSingle_image = await dbExecution(query_image, values_image);
   
    const query = `INSERT INTO public.tbland(
      id, area, price, contactnumber, locationurl, moredetail, status, createdate, provinceid, districtid, villageid,view_number)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`;
      let values = [id, landside, price,contactnumber, locationurl, moredetail, '1', 'NOW()', provinceid, districtid, villageid,'9'];
    const resultSingle = await dbExecution(query,values);
 
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

export const update_active_status_land_data = async (req, res) => {

   const {id, status}=req.body;

  try {
    const query = `UPDATE public.tbland SET  status=$1 WHERE id=$2 RETURNING *`; // done
    let values = [status, id];
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

export const update_side_and_price_land_data = async (req, res) => {   // done

  const {id,side,price}=req.body

  try {
    const query = `UPDATE public.tbland SET area=$1, price=$2 WHERE id=$3 RETURNING *`;
    let values = [side, price, id];
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

export const update_new_link_and_detail_land_data = async (req, res) => {  // done

const {id,new_link,detail}=req.body;

  try {
    const query = `UPDATE public.tbland SET locationurl=$1, moredetail=$2 WHERE id=$3 RETURNING *`;
    let values = [new_link, detail, id];
    const resultSingle = await dbExecution(query,values);

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
  
export const update_view_number_of_this_id = async (req, res) => {  // done
  
  const id=req.body.id;
 
    try {

    const query_v =`SELECT view_number FROM public.tbland where id=$1`;

    const result = await dbExecution(query_v, [id]);
    let view_number = result.rows[0].view_number; 
    view_number +=1;

      const query = `UPDATE public.tbland SET view_number=$1 WHERE id=$2 RETURNING *`;
      let values = [view_number, id];
      const resultSingle = await dbExecution(query,values);
     
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