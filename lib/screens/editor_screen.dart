import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/canvas_provider.dart';
import '../models/canvas_object.dart';
import '../animations/animated_drawing_widget.dart';

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
        ],
      ),
      body: Column(
        children: [
          // Scene Switcher (Top)
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
                    center: Text("Slide ${i + 1}", style: TextStyle(color: provider.currentSceneIndex == i ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          // Canvas Area
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: provider.resolution.width / provider.resolution.height,
                child: Container(
                  color: provider.currentScene.backgroundColor,
                  child: Stack(
                    children: provider.currentScene.objects.map((obj) => Positioned(
                      left: obj.x, top: obj.y,
                      child: GestureDetector(
                        onPanUpdate: (d) => provider.updateObjectPosition(obj.id, d.delta.dx, d.delta.dy),
                        child: AnimatedDrawingWidget(object: obj, isPlaying: isPlaying, handIndex: provider.selectedHandIndex),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
          // Bottom Toolbar
          Container(
            height: 100,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toolIcon(Icons.text_fields, "Text", () => _showTextDialog(context)),
                _toolIcon(Icons.image, "Image", () async {
                  FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (r != null) provider.addObject(CanvasObject(type: ObjectType.image, data: r.files.single.path!));
                }),
                _toolIcon(Icons.palette, "BG Color", () => provider.updateSceneColor(Colors.blue[100]!)),
                FloatingActionButton(onPressed: () => provider.togglePlay(), child: Icon(isPlaying ? Icons.stop : Icons.play_arrow)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHandPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (ctx) => Container(
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
