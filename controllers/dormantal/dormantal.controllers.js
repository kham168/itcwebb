import { dbExecution } from "../../config/dbConfig.js";

export const query_dormantal_dataall = async (req, res) => {         // done
  try {
    const query = `SELECT a.id, price1, price2, price3, type, totalroom, activeroom, locationurl, 
    contactnumber, createdate, viewnumber, detail, active_status, dormantal_name, plan_on_next_month,
  d.district,v.arean,v.village,i.url FROM public.tbdormantalroom a inner join public.tbdistrict d on d.id=a.districtid
     inner join public.tbvillage v on v.id=a.villageid inner join public.tbdormantalimage i on a.id=i.id order by createdate desc limit 50`;
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
  
export const query_dormantal_dataone = async (req, res) => {           // done

  const id =req.body.id;

  try {
    const query = `SELECT a.id, price1, price2, price3, type, totalroom, activeroom, locationurl, 
    contactnumber, createdate, viewnumber, detail, active_status, dormantal_name, plan_on_next_month,
    d.district,v.arean,v.village,i.url FROM public.tbdormantalroom a inner join public.tbdistrict d on d.id=a.districtid
     inner join public.tbvillage v on v.id=a.villageid inner join public.tbdormantalimage i on a.id=i.id
     where a.id=$1`;
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
 
export const query_dormantal_data_by_district_or_arean_or_village = async (req, res) => {       // done

  const {district,arean,village} =req.body;

  try {
    const query = `SELECT a.id, price1, price2, price3, type, totalroom, activeroom, locationurl, 
    contactnumber, createdate, viewnumber, detail, active_status, dormantal_name, plan_on_next_month,
    d.district,v.arean,v.village,i.url FROM public.tbdormantalroom a inner join public.tbdistrict d on d.id=a.districtid
    inner join public.tbvillage v on v.id=a.villageid inner join public.tbdormantalimage i on a.id=i.id
    where d.district Ilike '%$1%' or v.arean Ilike '%$2%' or v.village Ilike '%$3%' order by a.viewnumber desc limit 25`;
    let values=[district, arean, village];
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
  
export const insert_dormantal_data = async (req, res) => {                      // done

  const data = req.body; 


   const {id, price1, price2, price3, type, totalroom, activeroom, locationurl, contactnumber, detail, provinceid, 
    districtid, villageid, dormantal_name }=req.body;

     if(req.file){
     data.file= req.file.filename;
      } 

  try {

       const query_image = `INSERT INTO public.tbdormantalimage(id, url) VALUES ($1, $2) RETURNING *`;
       let values_image=[id, data.file];
      const resultSingle_image = await dbExecution(query_image, values_image);
       
    const query = `INSERT INTO public.tbdormantalroom(
      id, price1, price2, price3, type, totalroom, activeroom, locationurl, contactnumber, createdate, viewnumber, detail, 
      provinceid, districtid, villageid, active_status, dormantal_name, plan_on_next_month)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18) RETURNING *`;
      let values =[id, price1, price2, price3, type, totalroom, activeroom, locationurl, contactnumber, 'NOW()','9', detail, provinceid, 
      districtid, villageid, '1', dormantal_name,'1'];
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
  
export const Update_active_Status_dormantal_data = async (req, res) => {           // done

   const {id, status}=req.body;

  try {
    const query = `update public.tbdormantalroom set active_status=$1 where id=$2 RETURNING *`;
    let values =[status,id];
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
 
export const Update_type_and_totalroom_and_active_room_dormantal_data = async (req, res) => {          // done

  const {id, dormantal_type, totalroom, number_roomactive}=req.body;

 try {
   const query = `update public.tbdormantalroom set type=$1, totalroom=$2, activeroom=$3 where id=$4 RETURNING *`;
   let values =[dormantal_type, totalroom, number_roomactive,id];
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


 
export const Update_contactinform_and_detailinform_and_plan_in_next_month_dormantal_data = async (req, res) => {       // done

  const {id,contactinform, detail,plan_in_next_month}=req.body;

 try {

   const query = `update public.tbdormantalroom set contactnumber=$1, detail=$2,plan_on_next_month=$3 where id=$4 RETURNING *`;
   
   let values = [contactinform, detail, plan_in_next_month, id];

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
 
export const Update_price_dormantal_data = async (req, res) => {         // done

  const {id, price1, price2, price3}=req.body;

 try {
   const query = `update public.tbdormantalroom set price1=$1, price2=$2, price3=$3 where id=$4 RETURNING *`;
   let values = [price1, price2, price3, id];
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
 
export const Update_view_number_of_this_id = async (req, res) => {       // done

  const id=req.body.id;
  
  try { 
 
 const query_v = `SELECT viewnumber FROM public.tbdormantalroom where id=$1`;

  const result = await dbExecution(query_v, [id]);
  let viewnumber = result.rows[0].viewnumber; 
  viewnumber +=1;
 
    const query = `update public.tbdormantalroom set viewnumber= $1 where id= $2 RETURNING *`;
    let values = [viewnumber, id];
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

  

 
   //router.post('/register',upload,register);


  
  //exports.upload = multer({ storage: storage }).single('file')
 
  
 //    var express = require('express');
//     var router = express.Router();
//     const {register,login} = require('../controller/register')
//     const {upload} = require('../middleware/upload')


//exports.register = async(req,res)=>{
   // try {

  /// <<<<========    nw yeej comment cia ua ntej no lawm.
    //     const {email,fname,password}= req.body
    //     const user = await User.findOne({where:{fname}})
    //     if(user){ return res.send("Email already Exists !!!").status(400)
    //     }   const salt= await bcrypt.genSalt(10)
    //     const adduser = new User({ email, fname, password })
    //     adduser.password = await bcrypt.hash(password,salt)

    //    await adduser.save()    res.send("Register Success")     console.log(adduser)
   /// =========>>>


    //const data= req.body;
   // if(req.file){
   //   data.file= req.file.filenamek
   // }
    //console.log(data)
   // const user=await Ownerstore({data})
    //await user.save()
   // res.send(user)
   // } catch (error) {  console.log(error);  res.status(500).send("server error")  } },
      
     // const {Ownerstore} = require('../config/db');
//const bcrypt= require('bcryptjs');
//const { where } = require('sequelize');
//const jwt = require('jsonwebtoken');