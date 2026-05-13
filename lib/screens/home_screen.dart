
import 'package:flutter/material.dart';

import 'editor_screen.dart';



class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('KAIDA Animate', style: TextStyle(fontWeight: FontWeight.bold)),

      ),

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(Icons.draw, size: 100, color: Color(0xFF800080)),

            const SizedBox(height: 24),

            ElevatedButton.icon(

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(builder: (context) => const EditorScreen()),

                );

              },

              icon: const Icon(Icons.add),

              label: const Text('New Project'),

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFF800080),

                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),

              ),

            ),

          ],

        ),

      ),

    );

  }

}

