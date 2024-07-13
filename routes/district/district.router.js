import Route from "express";
import { verifyJWT } from "../../middleware/jwt.js";
import { query_district_dataall, query_district_dataone, insert_district_data, update_district_data } from "../../controllers/district/district.controllers.js";
const route = Route();

route.get("/selectall", query_district_dataall);
route.post("/selectone", query_district_dataone);
route.post("/insert", insert_district_data);
route.put("/update", update_district_data);
 
export default route;