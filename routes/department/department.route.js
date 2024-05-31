import Route from 'express';
import { verifyJWT } from '../../middleware/jwt.js';
import { changeDepartmentStatus, createDepartment, deleteDepartment, readDepartment, updateDepartment } from '../../controllers/department/department.controller.js';
const route = Route();

route.post('/department-create', verifyJWT, createDepartment);
route.put('/department-modify', verifyJWT, updateDepartment);
route.delete('/department-delete', verifyJWT, deleteDepartment);
route.put('/department-status', verifyJWT, changeDepartmentStatus);
route.get('/department-read', verifyJWT, readDepartment);


export default route;