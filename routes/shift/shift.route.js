import Route from 'express';
import { verifyJWT } from '../../middleware/jwt.js';
import { createShiftType, readShiftType } from '../../controllers/shift/shiftType.controller.js';
import { changeShiftStatus, createShift, deleteShift, readShift, updateShift } from '../../controllers/shift/shift.controller.js';
const route = Route();

//shift type
route.post('/shift-type-create', verifyJWT, createShiftType);
route.get('/shift-type-read', verifyJWT, readShiftType);

//shift
route.post('/shift-create', verifyJWT, createShift);
route.put('/shift-modify', verifyJWT, updateShift);
route.delete('/shift-delete', verifyJWT, deleteShift);
route.put('/shift-status',verifyJWT, changeShiftStatus);
route.get('/shift-read', verifyJWT, readShift);


export default route;