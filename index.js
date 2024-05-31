import express from 'express';
import bodyParser from 'body-parser';
import cookieParser from 'cookie-parser';
import { cors } from './config/corsOption.js';
// import { dbMiddleware } from './config/dbConfig.js';
import { requestLimiter } from './config/requestLimited.js';
import { errorHandle } from './middleware/errorHandle.js';
import { logger } from './middleware/logEvent.js';
//route
import authRoute from './routes/auth/auth.route.js';
import refreshTokenRoute from './routes/auth/refreshToken.route.js';
import locationRoute from './routes/location/location.route.js';
import locationDetailRoute from './routes/location/location.detail.route.js';
import departmentRoute from './routes/department/department.route.js';
import shiftRoute from './routes/shift/shift.route.js';
import taxTypeRoute from './routes/tax/tax.route.js';
import currencyRoute from './routes/currency/currency.route.js';

const app = express();
app.use(cors);
app.use(bodyParser.json());
app.use(cookieParser());
app.use(requestLimiter);
app.use(logger);
// app.use(dbMiddleware);

//route
app.use('/api', authRoute);
app.use('/api', refreshTokenRoute);
app.use('/api', locationRoute);
app.use('/api', locationDetailRoute);
app.use('/api', departmentRoute);
app.use('/api', shiftRoute);
app.use('/api', taxTypeRoute);
app.use('/api', currencyRoute);

app.use(errorHandle);

const APPPORT = Number(process.env.APPPORT);

app.listen(APPPORT,()=>{
    console.log(`App is running on port ${APPPORT}`);
})