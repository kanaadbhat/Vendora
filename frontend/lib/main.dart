import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 
import 'package:frontend/screens/auth.dart';


final theme = ThemeData(
  useMaterial3: true,
  // colorScheme: ColorScheme.fromSeed(
  //   brightness: Brightness.dark,
  //   seedColor: const Color.fromARGB(255, 131, 57, 0),
  // ),
  //textTheme: GoogleFonts.latoTextTheme(),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vendora',
      theme:theme,
      home: const AuthScreen(),
    );
  }
}
