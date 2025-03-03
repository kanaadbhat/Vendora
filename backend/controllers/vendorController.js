import { db } from "../config/firebase.js";
import { collection, doc, setDoc, getDoc, updateDoc,arrayUnion } from "firebase/firestore";
import { asyncHandler } from "../utils/asyncHandler.js";

//--------ADD VENDOR
export const registerVendor = asyncHandler(async (req, res) => {
  
    const { vendorName, phoneNumber } = req.body;

    if (!vendorName || !phoneNumber) {
      return res
        .status(400)
        .send({ message: "Missing VendorName or phoneNumber", success: false });
    }

    await setDoc(doc(collection(db, "vendors"), phoneNumber), {
      name: vendorName,
      phone: phoneNumber,
      authorizedNumbers: [],
      createdAt: new Date(),
    });

    res
      .status(200)
      .send({ message: "Vendor Registered Succesfully", success: true });
});

//-------------GET VENDOR
export const getVendorData = asyncHandler(async (req, res) => {
 
    const { phoneNumber } = req.params;

    if (!phoneNumber) {
      return res
        .status(400)
        .send({ message: "Missing phoneNumber", success: false });
    }

    const vendorRef = doc(db, "vendors", phoneNumber);
    const vendorSnap = await getDoc(vendorRef);

    if (!vendorSnap.exists()) {
      return res
        .status(404)
        .send({ message: "Vendor not found", success: false });
    }

    res.status(200).send({ success: true, data: vendorSnap.data() });
});

//  Add customer to list of authorised vendors
export const addCustomer = asyncHandler(async (req, res) => {
    const { vendorPhone, customerPhone } = req.body;
    if (!vendorPhone || !customerPhone) {
      res
        .status(400)
        .send({
          message: "Missing vendorPhone or CustomerPhone",
          success: false,
        });
    }

    const vendorRef = doc(db, "vendors", vendorPhone); // Corrected syntax

    await updateDoc(vendorRef, {
      authorizedNumbers: arrayUnion(customerPhone),
    });

    res
      .status(200)
      .send({ message: "Customer Added Succesfully ", success: true });
});
