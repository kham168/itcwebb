import Route from "express";
import { verifyJWT } from "../../middleware/jwt.js";
import { query_dormantal_dataall,query_dormantal_dataone,query_dormantal_data_by_district_or_arean_or_village, insert_dormantal_data,Update_active_Status_dormantal_data,Update_type_and_totalroom_and_active_room_dormantal_data,Update_contactinform_and_detailinform_and_plan_in_next_month_dormantal_data,Update_price_dormantal_data,Update_view_number_of_this_id } from "../../controllers/dormantal/dormantal.controllers.js";
import { uploadimage } from "../../middleware/dormantal.uploadimage.js";
const route = Route();

route.get("/selectall", query_dormantal_dataall);
route.post("/selectone", query_dormantal_dataone);
route.post("/selectby_district_or_arean_or_village", query_dormantal_data_by_district_or_arean_or_village);
route.post("/insert",uploadimage, insert_dormantal_data); 
route.put("/update_active_status", Update_active_Status_dormantal_data);
route.put("/update_type_and_totalroom_and_active_room", Update_type_and_totalroom_and_active_room_dormantal_data); 
route.put("/update_contact_and_detail_and_plan_in_next_month", Update_contactinform_and_detailinform_and_plan_in_next_month_dormantal_data);
route.put("/update_price", Update_price_dormantal_data);
route.put("/update_view_number_of_this_id", Update_view_number_of_this_id);

export default route;