import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../models/canvas_object.dart';
import '../animations/animated_drawing_widget.dart';
import 'export_screen.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CanvasProvider>();
    final isPlaying = provider.isPlaying;
    final selectedObj = provider.selectedObject;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('KAIDA Editor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF800080),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.upload_file), onPressed: () {
            if (provider.isPlaying) provider.togglePlay();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportScreen()));
          }),
        ],
      ),
      body: Column(
        children: [
          // Canvas Area
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: provider.resolution.width / provider.resolution.height,
                child: Container(
                  color: provider.currentScene.backgroundColor,
                  child: Stack(
                    children: provider.currentScene.objects.map((obj) {
                      final isSelected = obj.id == provider.selectedObjectId;
                      return Positioned(
                        left: obj.x, top: obj.y,
                        child: GestureDetector(
                          onTap: () => provider.selectObject(obj.id),
                          onPanUpdate: (d) => provider.updateObjectPosition(obj.id, d.delta.dx, d.delta.dy),
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: isSelected && !isPlaying ? const Color(0xFF800080) : Colors.transparent, width: 2)),
                            child: AnimatedDrawingWidget(object: obj, isPlaying: isPlaying, handIndex: provider.selectedHandIndex),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          
          // Benime-Style Bottom Properties Panel
          if (selectedObj != null && !isPlaying)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPropertySpinner('Delay', selectedObj.delay, (v) => provider.updateObjectTiming(selectedObj.id, delay: v)),
                      _buildPropertySpinner('Duration', selectedObj.duration, (v) => provider.updateObjectTiming(selectedObj.id, duration: v)),
                      _buildPropertySpinner('Pause', selectedObj.pause, (v) => provider.updateObjectTiming(selectedObj.id, pause: v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(onPressed: () => provider.deleteSelectedObject(), icon: const Icon(Icons.delete, color: Colors.red), label: const Text("Delete")),
                    ],
                  )
                ],
              ),
            ),

          // Main Toolbar
          if (selectedObj == null || isPlaying)
            Container(
              height: 70,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.text_fields), onPressed: () => provider.addObject(CanvasObject(type: ObjectType.text, data: "New Text"))),
                  IconButton(icon: const Icon(Icons.gesture), onPressed: () => provider.addObject(CanvasObject(type: ObjectType.drawing, data: "Path"))),
                  FloatingActionButton(backgroundColor: const Color(0xFF800080), foregroundColor: Colors.white, onPressed: () => provider.togglePlay(), child: Icon(isPlaying ? Icons.stop : Icons.play_arrow)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertySpinner(String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 20), onPressed: value > 0 ? () => onChanged(value - 0.5) : null),
            Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.keyboard_arrow_up, size: 20), onPressed: () => onChanged(value + 0.5)),
          ],
        )
      ],
    );
  }
}
