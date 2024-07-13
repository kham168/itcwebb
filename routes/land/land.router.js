import Route from "express";
import { verifyJWT } from "../../middleware/jwt.js";
import { query_land_dataall, query_land_dataone,query_land_data_by_district_or_arean_or_village, insert_land_data, update_active_status_land_data,update_side_and_price_land_data, update_new_link_and_detail_land_data,update_view_number_of_this_id } from "../../controllers/land/land.controllers.js";
import { uploadimage } from "../../middleware/land.uploadimage.js";
const route = Route();

route.get("/selectall", query_land_dataall);
route.post("/selectone", query_land_dataone);
route.post("/selectby_district_or_arean_or_village", query_land_data_by_district_or_arean_or_village);
route.post("/insert",uploadimage,insert_land_data);
route.put("/update_active_status_land_data", update_active_status_land_data);
route.put("/update_side_and_price_land_data", update_side_and_price_land_data);
route.put("/update_new_link_and_detail_land_data", update_new_link_and_detail_land_data);
route.put("/update_view_number_of_this_id", update_view_number_of_this_id);

export default route;
