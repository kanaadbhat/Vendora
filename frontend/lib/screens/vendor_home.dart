import 'package:flutter/material.dart';

class VendorHome extends StatefulWidget {
  const VendorHome({ super.key });

  @override
  State<VendorHome> createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Vendor Home Page")),
        body: Center(
          child: Text(
            "Hi",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}