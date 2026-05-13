import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../animations/animated_drawing_widget.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.watch<CanvasProvider>().isPlaying;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Selected',
            onPressed: () => context.read<CanvasProvider>().deleteSelectedObject(),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project saved locally.'), backgroundColor: Color(0xFF800080)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar Container (Glassmorphism inspired clean UI)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolBtn(context, Icons.title, 'Text', () {
                  context.read<CanvasProvider>().addTextObject('Tap to Edit');
                }),
                _buildToolBtn(context, Icons.draw, 'Draw Path', () {
                  context.read<CanvasProvider>().addDrawingObject();
                }),
                _buildToolBtn(context, Icons.image, 'Image', () {}),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey.shade300,
                ),
                FloatingActionButton.small(
                  backgroundColor: isPlaying ? Colors.redAccent : const Color(0xFF800080),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  onPressed: () => context.read<CanvasProvider>().togglePlay(),
                  child: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                ),
              ],
            ),
          ),
          // Infinite Canvas Area
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<CanvasProvider>().selectObject(null),
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
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
                                    color: isSelected && !isPlaying ? const Color(0xFF800080) : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: AnimatedDrawingWidget(
                                  object: obj,
                                  isPlaying: isPlaying,
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
          ),
          // Basic Timeline UI (Foundation for Phase 3)
          Container(
            height: 90,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timeline Sequence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Expanded(
                  child: Consumer<CanvasProvider>(
                    builder: (context, provider, child) {
                      if (provider.objects.isEmpty) {
                        return const Center(child: Text('Add objects to see timeline', style: TextStyle(color: Colors.grey, fontSize: 12)));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.objects.length,
                        itemBuilder: (context, index) {
                          final obj = provider.objects[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF800080).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: const Color(0xFF800080).withOpacity(0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                Icon(
                                  obj.type == ObjectType.text ? Icons.title : Icons.draw,
                                  size: 16,
                                  color: const Color(0xFF800080),
                                ),
                                const SizedBox(width: 8),
                                Text('${index + 1} (${obj.duration.inSeconds}s)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
