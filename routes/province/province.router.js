
import Route from "express";
import { verifyJWT } from "../../middleware/jwt.js";
import { quer_province_dataall, quer_province_dataone} from "../../controllers/province/province.controllers.js"; //"../../controllers/provice/provice.controllers.js";
const route = Route();

route.get("/selectall", quer_province_dataall);
route.post("/selectone", quer_province_dataone);

export default route;


