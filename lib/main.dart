
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'providers/canvas_provider.dart';

import 'screens/home_screen.dart';



void main() {

  runApp(

    MultiProvider(

      providers: [

        ChangeNotifierProvider(create: (_) => CanvasProvider()),

      ],

      child: const KaidaAnimateApp(),

    ),

  );

}



class KaidaAnimateApp extends StatelessWidget {

  const KaidaAnimateApp({super.key});



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'KAIDA Animate',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        primaryColor: const Color(0xFF800080), // KAIDA Purple

        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF800080)),

        useMaterial3: true,

        appBarTheme: const AppBarTheme(

          backgroundColor: Color(0xFF800080),

          foregroundColor: Colors.white,

          elevation: 0,

        ),

      ),

      home: const HomeScreen(),

    );

  }

}

