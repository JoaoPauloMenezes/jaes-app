import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  ).then((value) => print('Firebase initialized'));

  FirebaseDatabase database = FirebaseDatabase.instance;

  runApp(MyApp(
    firebaseDatabase: database,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? super.key,
    required this.firebaseDatabase
  });

  final FirebaseDatabase firebaseDatabase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(

      ),
      // home: const LoginScreen(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}