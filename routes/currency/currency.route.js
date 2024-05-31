import Route from 'express';
import { verifyJWT } from '../../middleware/jwt.js';
import { changeCurrencyStatus, createCurrency, deleteCurrency, readCurrency, updateCurrency } from '../../controllers/currency/currency.controller.js';

const route = Route();

route.post('/currency-create', verifyJWT, createCurrency);
route.put('/currency-modify', verifyJWT, updateCurrency);
route.delete('/currency-delete', verifyJWT, deleteCurrency);
route.put('/currency-status', verifyJWT, changeCurrencyStatus);
route.get('/currency-read', verifyJWT, readCurrency);

export default route;