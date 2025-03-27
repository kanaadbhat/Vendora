import 'package:flutter/material.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({ super.key });

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  @override
  Widget build(BuildContext context) {
     return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Customer Home Page")),
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