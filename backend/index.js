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
app.use('/api/user' , userRouter);
app.use('/api/vendorProduct',vendorProductRouter);
app.use('/api/userProduct',userProductRouter);

app.listen(process.env.PORT , () => {
    connectDB();
    console.log(`Server running on port ${process.env.PORT}`);
})