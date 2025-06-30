import mongoose from 'mongoose';

const userSchema = mongoose.Schema({
    email : {
        type: String,
        required: true,
        unique: true
    },
    password : {
        type: String,
        required: true
    },
    name : {
        type: String,
        required: true
    },
    phone : {
        type: String,
        required: true
    },
    role : {
        type : String,
        required:true,
    },
    businessName: {
        type: String,
    },
    businessDescription: {
        type: String,
    },
    profileimage : {
        type: String,
        required: true
    },
});

export const User = mongoose.model('User', userSchema);

