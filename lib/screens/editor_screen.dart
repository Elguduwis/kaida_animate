import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/canvas_provider.dart';
import '../models/canvas_object.dart';
import '../animations/animated_drawing_widget.dart';
import 'export_screen.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  void _showTextDialog(BuildContext context) {
    final controller = TextEditingController();
    Color selectedColor = Colors.black;
    double fontSize = 24.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter text...")),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Color: "),
                  ...[Colors.black, Colors.red, Colors.blue, Colors.purple].map((c) => GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 24, height: 24, color: c, child: selectedColor == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
                  )),
                ],
              ),
              Slider(value: fontSize, min: 12, max: 100, onChanged: (v) => setState(() => fontSize = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () {
              context.read<CanvasProvider>().addObject(CanvasObject(type: ObjectType.text, data: controller.text, color: selectedColor, fontSize: fontSize));
              Navigator.pop(ctx);
            }, child: const Text('Add')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CanvasProvider>();
    final isPlaying = provider.isPlaying;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.currentProjectName),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () => provider.saveProject()),
          IconButton(icon: const Icon(Icons.back_hand), onPressed: () => _showHandPicker(context)),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              if (provider.isPlaying) provider.togglePlay();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scene Switcher
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.scenes.length + 1,
              itemBuilder: (context, i) {
                if (i == provider.scenes.length) return IconButton(icon: const Icon(Icons.add_box), onPressed: () => provider.addScene());
                return GestureDetector(
                  onTap: () => provider.selectScene(i),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: provider.currentSceneIndex == i ? const Color(0xFF800080) : Colors.grey[300], borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center, // FIX: Used alignment instead of non-existent 'center' parameter
                    child: Text("Slide ${i + 1}", style: TextStyle(color: provider.currentSceneIndex == i ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          // Canvas Area
          Expanded(
            flex: 6,
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
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected && !isPlaying ? const Color(0xFF800080) : Colors.transparent, width: 2),
                            ),
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
          // Timeline & Layers
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Timeline & Layers', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (provider.audioFileName != null)
                          Chip(
                            label: Text(provider.audioFileName!, maxLines: 1),
                            onDeleted: () => provider.removeAudioTrack(),
                            backgroundColor: const Color(0xFF800080).withOpacity(0.1),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: provider.currentScene.objects.length,
                      onReorder: (oldIdx, newIdx) => provider.reorderObjects(oldIdx, newIdx),
                      itemBuilder: (context, index) {
                        final obj = provider.currentScene.objects[index];
                        final isSelected = obj.id == provider.selectedObjectId;
                        return Card(
                          key: ValueKey(obj.id),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: isSelected ? const Color(0xFF800080).withOpacity(0.05) : Colors.white,
                          child: ListTile(
                            leading: Icon(obj.type == ObjectType.text ? Icons.title : Icons.gesture),
                            title: Text(obj.data),
                            subtitle: Text('Start: ${obj.startTime.inSeconds}s'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: obj.duration.inSeconds > 1 ? () => provider.updateDuration(obj.id, obj.duration.inSeconds - 1) : null),
                                Text('${obj.duration.inSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => provider.updateDuration(obj.id, obj.duration.inSeconds + 1)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () { provider.selectObject(obj.id); provider.deleteSelectedObject(); }),
                                const Icon(Icons.drag_handle, color: Colors.grey),
                              ],
                            ),
                            onTap: () => provider.selectObject(obj.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Toolbar
          Container(
            height: 80,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toolIcon(Icons.text_fields, "Text", () => _showTextDialog(context)),
                _toolIcon(Icons.image, "Image", () async {
                  FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (r != null) provider.addObject(CanvasObject(type: ObjectType.image, data: r.files.single.path!));
                }),
                _toolIcon(Icons.audiotrack, "Music", () => provider.pickAudio()),
                FloatingActionButton(onPressed: () => provider.togglePlay(), child: Icon(isPlaying ? Icons.stop : Icons.play_arrow)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHandPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: 5,
        itemBuilder: (context, i) => InkWell(
          onTap: () { context.read<CanvasProvider>().setHand(i); Navigator.pop(ctx); },
          child: Center(child: Text(['✍🏽', '🖐🏿', '🖊️', '🖌️', '🖍️'][i], style: const TextStyle(fontSize: 40))),
        ),
      ),
    ));
  }

  Widget _toolIcon(IconData icon, String label, VoidCallback tap) => InkWell(onTap: tap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), Text(label, style: const TextStyle(fontSize: 10))]));
}
