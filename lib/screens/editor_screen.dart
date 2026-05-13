import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../animations/animated_drawing_widget.dart';
import '../models/canvas_object.dart';
import 'export_screen.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.watch<CanvasProvider>().isPlaying;
    final projectName = context.watch<CanvasProvider>().currentProjectName;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: Text(projectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF800080),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Project',
            onPressed: () async {
              await context.read<CanvasProvider>().saveProject();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project Saved!'), backgroundColor: Colors.green),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export Video',
            onPressed: () {
              if (context.read<CanvasProvider>().isPlaying) {
                context.read<CanvasProvider>().togglePlay();
              }
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolBtn(context, Icons.text_fields, 'Text', () => context.read<CanvasProvider>().addTextObject('New Text')),
                _buildToolBtn(context, Icons.gesture, 'Draw', () => context.read<CanvasProvider>().addDrawingObject()),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                FloatingActionButton.extended(
                  backgroundColor: isPlaying ? Colors.redAccent : const Color(0xFF800080),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(isPlaying ? "Stop" : "Preview"),
                  onPressed: () => context.read<CanvasProvider>().togglePlay(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: () => context.read<CanvasProvider>().selectObject(null),
              child: Container(
                margin: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
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
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ),
                                ),
                                child: AnimatedDrawingWidget(object: obj, isPlaying: isPlaying),
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
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.black12, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade50,
                    child: const Text('Timeline & Layers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  Expanded(
                    child: Consumer<CanvasProvider>(
                      builder: (context, provider, child) {
                        if (provider.objects.isEmpty) {
                          return const Center(child: Text('Add objects to build your video timeline.'));
                        }
                        return ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: provider.objects.length,
                          onReorder: (oldIndex, newIndex) => provider.reorderLayers(oldIndex, newIndex),
                          itemBuilder: (context, index) {
                            final obj = provider.objects[index];
                            final isSelected = obj.id == provider.selectedObjectId;
                            
                            return Card(
                              key: ValueKey(obj.id),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              elevation: isSelected ? 2 : 0,
                              color: isSelected ? const Color(0xFF800080).withOpacity(0.05) : Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: isSelected ? const Color(0xFF800080) : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: ListTile(
                                leading: Icon(obj.type == ObjectType.text ? Icons.title : Icons.gesture, color: const Color(0xFF800080)),
                                title: Text(obj.data, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('Start: ${obj.startTime.inSeconds}s'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: obj.duration.inSeconds > 1 ? () => provider.updateDuration(obj.id, obj.duration.inSeconds - 1) : null,
                                    ),
                                    Text('${obj.duration.inSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => provider.updateDuration(obj.id, obj.duration.inSeconds + 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        provider.selectObject(obj.id);
                                        provider.deleteSelectedObject();
                                      },
                                    ),
                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                  ],
                                ),
                                onTap: () => provider.selectObject(obj.id),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF800080)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
