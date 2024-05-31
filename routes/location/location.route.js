import Route from 'express';
import { verifyJWT } from '../../middleware/jwt.js';
import { readScreen } from '../../controllers/screens/screens.controller.js';
import { changeLocationStatus, createLocation, deleteLocation, readLocation, updateLocation } from '../../controllers/location/location.controller.js';
import { upload } from '../../utils/multerHelper.js'
const route = Route();

route.get('/user-menu', verifyJWT, readScreen);
route.post('/location-create', verifyJWT,upload.fields([
  { name: 'Profile', maxCount: 1 },
  { name: 'LocationLogo', maxCount: 1 }, 
]), createLocation);
route.put('/location-modify', verifyJWT,upload.fields([
  { name: 'Profile', maxCount: 1 },
  { name: 'LocationLogo', maxCount: 1 }, 
]), updateLocation);

route.delete('/location-delete', verifyJWT, deleteLocation);
route.put('/location-status', verifyJWT, changeLocationStatus);
route.get('/location-read', verifyJWT, readLocation);


export default route;