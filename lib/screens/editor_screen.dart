
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/canvas_provider.dart';



class EditorScreen extends StatelessWidget {

  const EditorScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[200],

      appBar: AppBar(

        title: const Text('Canvas Editor'),

        actions: [

          IconButton(

            icon: const Icon(Icons.delete),

            onPressed: () {

              context.read<CanvasProvider>().deleteSelectedObject();

            },

          ),

          IconButton(

            icon: const Icon(Icons.save),

            onPressed: () {

              // MVP save placeholder

              ScaffoldMessenger.of(context).showSnackBar(

                const SnackBar(content: Text('Project saved locally.')),

              );

            },

          ),

        ],

      ),

      body: Column(

        children: [

          // Toolbar

          Container(

            color: Colors.white,

            padding: const EdgeInsets.all(8.0),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [

                ActionChip(

                  label: const Text('Add Text'),

                  avatar: const Icon(Icons.text_fields, size: 16),

                  onPressed: () {

                    context.read<CanvasProvider>().addTextObject('New Text');

                  },

                ),

                ActionChip(

                  label: const Text('Add Shape'),

                  avatar: const Icon(Icons.category, size: 16),

                  onPressed: () {

                    // Placeholder for shapes

                  },

                ),

              ],

            ),

          ),

          // Canvas Area

          Expanded(

            child: GestureDetector(

              onTap: () => context.read<CanvasProvider>().selectObject(null),

              child: Container(

                margin: const EdgeInsets.all(16.0),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(8.0),

                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],

                ),

                child: Consumer<CanvasProvider>(

                  builder: (context, provider, child) {

                    return Stack(

                      children: provider.objects.map((obj) {

                        final isSelected = obj.id == provider.selectedObjectId;

                        return Positioned(

                          left: obj.x,

                          top: obj.y,

                          child: GestureDetector(

                            onTap: () => provider.selectObject(obj.id),

                            onPanUpdate: (details) {

                              provider.selectObject(obj.id);

                              provider.updateObjectPosition(obj.id, details.delta.dx, details.delta.dy);

                            },

                            child: Container(

                              decoration: BoxDecoration(

                                border: Border.all(

                                  color: isSelected ? const Color(0xFF800080) : Colors.transparent,

                                  width: 2,

                                ),

                              ),

                              padding: const EdgeInsets.all(4),

                              child: Text(

                                obj.data,

                                style: const TextStyle(fontSize: 24, color: Colors.black87),

                              ),

                            ),

                          ),

                        );

                      }).toList(),

                    );

                  },

                ),

              ),

            ),

          ),

          // Simple Timeline Placeholder

          Container(

            height: 80,

            color: Colors.white,

            child: const Center(

              child: Text(

                'Timeline area (Coming in Phase 2)',

                style: TextStyle(color: Colors.grey),

              ),

            ),

          ),

        ],

      ),

    );

  }

}

