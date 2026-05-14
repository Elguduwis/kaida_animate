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
    Color selectedColor = Colors.black; double fontSize = 40.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: const Text('Add Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter text...")),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [Colors.black, Colors.red, Colors.blue, Colors.purple, Colors.green].map((c) => GestureDetector(
                onTap: () => setState(() => selectedColor = c),
                child: Container(width: 30, height: 30, color: c, child: selectedColor == c ? const Icon(Icons.check, color: Colors.white) : null),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            context.read<CanvasProvider>().addObject(CanvasObject(type: ObjectType.text, data: controller.text, color: selectedColor, fontSize: fontSize));
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      )),
    );
  }

  @override Widget build(BuildContext context) {
    final provider = context.watch<CanvasProvider>();
    final isPlaying = provider.isPlaying;
    final selectedObj = provider.selectedObject;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(provider.currentProjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF800080), foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () {
            provider.saveProject();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project Saved!'), backgroundColor: Colors.green));
          }),
          IconButton(icon: const Icon(Icons.back_hand), onPressed: () => _showHandPicker(context)),
          IconButton(icon: const Icon(Icons.upload_file), onPressed: () {
            if (provider.isPlaying) provider.togglePlay();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExportScreen()));
          }),
        ],
      ),
      body: Column(
        children: [
          // Scene Switcher
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: provider.scenes.length + 1,
              itemBuilder: (context, i) {
                if (i == provider.scenes.length) return IconButton(icon: const Icon(Icons.add_box), onPressed: () => provider.addScene());
                return GestureDetector(
                  onTap: () => provider.selectScene(i),
                  child: Container(
                    margin: const EdgeInsets.all(8), padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: provider.currentSceneIndex == i ? const Color(0xFF800080) : Colors.grey[300], borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: Text("Slide ${i + 1}", style: TextStyle(color: provider.currentSceneIndex == i ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          
          // Canvas Area
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () => provider.selectObject(null),
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
          ),
          
          // HYBRID PANEL: Properties OR Timeline
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: selectedObj != null && !isPlaying
                  ? _buildPropertiesPanel(selectedObj, provider)
                  : _buildTimeline(provider),
            ),
          ),

          // Main Toolbar
          if (selectedObj == null || isPlaying)
            Container(
              height: 70, color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _toolIcon(Icons.text_fields, "Text", () => _showTextDialog(context)),
                  _toolIcon(Icons.image, "Image", () async {
                    FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (r != null) provider.addObject(CanvasObject(type: ObjectType.image, data: r.files.single.path!));
                  }),
                  _toolIcon(Icons.audiotrack, "Music", () => provider.pickAudio()),
                  FloatingActionButton(backgroundColor: const Color(0xFF800080), foregroundColor: Colors.white, onPressed: () => provider.togglePlay(), child: Icon(isPlaying ? Icons.stop : Icons.play_arrow)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(CanvasProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8), color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Layers (Tap to Edit, Drag to Reorder)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              if (provider.audioFileName != null)
                Chip(label: Text(provider.audioFileName!, maxLines: 1), onDeleted: () => provider.removeAudioTrack(), backgroundColor: const Color(0xFF800080).withOpacity(0.1)),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: provider.currentScene.objects.length,
            onReorder: (oldIdx, newIdx) => provider.reorderObjects(oldIdx, newIdx),
            itemBuilder: (context, index) {
              final obj = provider.currentScene.objects[index];
              return Card(
                key: ValueKey(obj.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(obj.type == ObjectType.text ? Icons.title : Icons.gesture, color: const Color(0xFF800080)),
                  title: Text(obj.data),
                  subtitle: Text('Start: ${(obj.startTime.inMilliseconds / 1000).toStringAsFixed(1)}s | Delay: ${obj.delay}s'),
                  trailing: const Icon(Icons.drag_handle),
                  onTap: () => provider.selectObject(obj.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesPanel(CanvasObject obj, CanvasProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Properties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => provider.selectObject(null)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSpinner('Delay', obj.delay, (v) => provider.updateObjectTiming(obj.id, delay: v)),
              _buildSpinner('Duration', obj.duration, (v) => provider.updateObjectTiming(obj.id, duration: v)),
              _buildSpinner('Pause', obj.pause, (v) => provider.updateObjectTiming(obj.id, pause: v)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            onPressed: () => provider.deleteSelectedObject(),
            icon: const Icon(Icons.delete), label: const Text("Delete Object"),
          )
        ],
      ),
    );
  }

  Widget _buildSpinner(String label, double value, Function(double) onChanged) {
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

  void _showHandPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), itemCount: 5,
        itemBuilder: (context, i) => InkWell(
          onTap: () { context.read<CanvasProvider>().setHand(i); Navigator.pop(ctx); },
          child: Center(child: Text(['✍🏽', '🖐🏿', '🖊️', '🖌️', '🖍️'][i], style: const TextStyle(fontSize: 40))),
        ),
      ),
    ));
  }

  Widget _toolIcon(IconData icon, String label, VoidCallback tap) => InkWell(onTap: tap, child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF800080)), const SizedBox(height:4), Text(label, style: const TextStyle(fontSize: 10))]));
}
