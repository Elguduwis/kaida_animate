import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/canvas_provider.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _savedProjects = [];

  @override void initState() { super.initState(); _loadProjectList(); }

  Future<void> _loadProjectList() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('project_')).toList();
    setState(() => _savedProjects = keys.map((k) => k.replaceFirst('project_', '')).toList());
  }

  Future<void> _deleteProject(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('project_$name');
    _loadProjectList();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('KAIDA Animate', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF800080), foregroundColor: Colors.white),
      body: _savedProjects.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library_outlined, size: 80, color: Colors.grey[400]), const SizedBox(height: 16), const Text('No projects yet. Start creating!', style: TextStyle(color: Colors.grey))]))
          : ListView.builder(
              padding: const EdgeInsets.all(16), itemCount: _savedProjects.length,
              itemBuilder: (context, index) {
                final projectName = _savedProjects[index];
                return Card(
                  elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF800080), child: Icon(Icons.movie_creation, color: Colors.white)),
                    title: Text(projectName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('Tap to edit'),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteProject(projectName)),
                    onTap: () async {
                      await context.read<CanvasProvider>().loadProject(projectName);
                      if (!mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditorScreen())).then((_) => _loadProjectList());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF800080), foregroundColor: Colors.white,
        icon: const Icon(Icons.add), label: const Text('New Project'),
        onPressed: () {
          context.read<CanvasProvider>().clearWorkspace();
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EditorScreen())).then((_) => _loadProjectList());
        },
      ),
    );
  }
}
