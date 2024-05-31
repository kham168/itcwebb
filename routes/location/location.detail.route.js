import Route from 'express';
import { verifyJWT } from '../../middleware/jwt.js';
import { upload } from '../../utils/multerHelper.js';
import { 
    changeLocationDetailStatus, 
    createLocationDetail, 
    deleteLocationDetail, 
    readLocationDetail, 
    updateLocationDetail 
} from '../../controllers/location/location.detail.controller.js';


const route = Route();

route.post('/location-detail-create', verifyJWT, upload.fields([
    {name: "QR", maxCount: 1}
]), createLocationDetail);

route.post('/location-detail-modify', verifyJWT, upload.fields([
    {name: "QR", maxCount: 1}
]), updateLocationDetail);

route.delete('/location-detail-delete', verifyJWT, deleteLocationDetail);
route.put('/location-detail-status',verifyJWT, changeLocationDetailStatus);
route.get('/location-detail-read', verifyJWT, readLocationDetail);

export default route;