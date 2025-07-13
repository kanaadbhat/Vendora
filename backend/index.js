import express from 'express'; 
import cors from 'cors';
import dotenv from 'dotenv';
import {connectDB} from './utils/connectDB.js';
import cookieParser from 'cookie-parser';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());
app.use(cookieParser());

import userRouter from './routes/user.routes.js';
import vendorProductRouter from './routes/vendorProduct.routes.js';
import userProductRouter from './routes/userProduct.routes.js';
import subscriptionDeliveries from './routes/subscriptionDelivery.routes.js';
import chatRouter from './routes/chat.routes.js';
import paymentRouter from './routes/payment.routes.js';

app.use('/api/user' , userRouter);
app.use('/api/vendorProduct',vendorProductRouter);
app.use('/api/userProduct',userProductRouter);
app.use('/api/subscriptionDelivery',subscriptionDeliveries);
app.use('/api/chat', chatRouter);
app.use('/api/pay',paymentRouter);

import "./utils/cron.js";
app.listen(process.env.PORT , '0.0.0.0', () => {
    connectDB();
    console.log(`Server running on port ${process.env.PORT}`);
})