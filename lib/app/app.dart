
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:music_app/features/home/home_screen.dart';
import 'package:music_app/features/welcome/welcome_screen.dart';

class RyvoApp extends StatelessWidget {
const RyvoApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: "RYVO",
theme: ThemeData(
useMaterial3: true,
brightness: Brightness.dark,
scaffoldBackgroundColor: Colors.black,
splashColor: Colors.transparent,
highlightColor: Colors.transparent,
colorScheme: const ColorScheme.dark(
primary: Color(0xFF8B5CF6),
surface: Colors.black,
),
),
home: StreamBuilder<User?>(
stream: FirebaseAuth.instance.authStateChanges(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Scaffold(
backgroundColor: Colors.black,
body: Center(
child: CircularProgressIndicator(
color: Color(0xFF8B5CF6),
),
),
);
}

if (snapshot.hasData) {
return const HomeScreen();
}

return const WelcomeScreen();
},
),
);
}
}

