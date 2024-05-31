import Route from "express";
import { verifyJWT } from '../../middleware/jwt.js';
import { readTaxType } from "../../controllers/tax/taxType.controller.js";
import { createTax, updateTax, deleteTax,changeTaxStatus,readTax} from "../../controllers/tax/tax.controller.js";

const route = Route();

route.get('/read-tax-type', verifyJWT, readTaxType);
route.post('/tax-create', verifyJWT, createTax);
route.put('/tax-modify', verifyJWT, updateTax);
route.delete('/tax-delete', verifyJWT, deleteTax);
route.put('/tax-status', verifyJWT, changeTaxStatus);
route.get('/tax-read',verifyJWT, readTax);

export default route;