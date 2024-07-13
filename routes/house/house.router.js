import Route from "express";
import { verifyJWT } from "../../middleware/jwt.js";
import { query_house_dataall, query_house_dataone,query_house_data_by_district_or_arean_or_village, 
    insert_house_data, update_active_status_house_data, update_price_house_data, 
    update_location_and_detail_house_data, update_side_of_land_and_house_data,
    update_view_number_of_id } from "../../controllers/house/house.controllers.js";
import { uploadimage } from "../../middleware/house.uploadimage.js";
const route = Route();


route.get("/selectall", query_house_dataall);
route.post("/selectone", query_house_dataone);
route.post("/selectby_province_or_district_or_arean_or_village", query_house_data_by_district_or_arean_or_village);
route.post("/insert", uploadimage,insert_house_data);
route.put("/update_active_status_house_data", update_active_status_house_data);
route.put("/update_price_house_data", update_price_house_data);
route.put("/update_location_and_detail_house_data", update_location_and_detail_house_data);
route.put("/update_side_of_land_and_house_data", update_side_of_land_and_house_data);
route.put("/update_view_number_of_id", update_view_number_of_id);

export default route;