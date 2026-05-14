import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/canvas_object.dart';

class CanvasProvider extends ChangeNotifier {
  List<Scene> _scenes = [Scene()];
  int _currentSceneIndex = 0;
  String? _selectedObjectId;
  bool _isPlaying = false;
  String _currentProjectName = "New Project";
  Size _resolution = const Size(1280, 720); 
  int _selectedHandIndex = 0; 
  String? _audioPath;
  String? _audioFileName;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Scene> get scenes => _scenes;
  int get currentSceneIndex => _currentSceneIndex;
  Scene get currentScene => _scenes[_currentSceneIndex];
  Size get resolution => _resolution;
  int get selectedHandIndex => _selectedHandIndex;
  String? get audioFileName => _audioFileName;
  bool get isPlaying => _isPlaying;
  String get currentProjectName => _currentProjectName;
  String? get selectedObjectId => _selectedObjectId;

  CanvasObject? get selectedObject {
    if (_selectedObjectId == null) return null;
    try { return currentScene.objects.firstWhere((o) => o.id == _selectedObjectId); } catch (e) { return null; }
  }

  void selectScene(int index) { _currentSceneIndex = index; _selectedObjectId = null; notifyListeners(); }
  void addScene() { _scenes.add(Scene()); _currentSceneIndex = _scenes.length - 1; notifyListeners(); }
  void setHand(int index) { _selectedHandIndex = index; notifyListeners(); }
  void updateSceneColor(Color color) { currentScene.backgroundColor = color; notifyListeners(); }

  void addObject(CanvasObject obj) {
    currentScene.objects.add(obj);
    _recalculateTimestamps();
    _selectedObjectId = obj.id;
    notifyListeners();
  }

  void selectObject(String? id) { _selectedObjectId = id; notifyListeners(); }

  void updateObjectPosition(String id, double dx, double dy) {
    final obj = currentScene.objects.firstWhere((o) => o.id == id);
    obj.x += dx; obj.y += dy;
    notifyListeners();
  }

  void reorderObjects(int oldIdx, int newIdx) {
    if (oldIdx < newIdx) newIdx -= 1;
    final obj = currentScene.objects.removeAt(oldIdx);
    currentScene.objects.insert(newIdx, obj);
    _recalculateTimestamps();
    notifyListeners();
  }

  void updateObjectTiming(String id, {double? delay, double? duration, double? pause}) {
    final obj = currentScene.objects.firstWhere((o) => o.id == id);
    if (delay != null) obj.delay = delay;
    if (duration != null) obj.duration = duration;
    if (pause != null) obj.pause = pause;
    _recalculateTimestamps();
    notifyListeners();
  }

  void deleteSelectedObject() {
    if (_selectedObjectId != null) {
      currentScene.objects.removeWhere((obj) => obj.id == _selectedObjectId);
      _selectedObjectId = null;
      _recalculateTimestamps();
      notifyListeners();
    }
  }

  void _recalculateTimestamps() {
    for (var scene in _scenes) {
      double currentSeconds = 0.0;
      for (var obj in scene.objects) {
        currentSeconds += obj.delay;
        obj.startTime = Duration(milliseconds: (currentSeconds * 1000).toInt());
        currentSeconds += obj.duration;
        currentSeconds += obj.pause;
      }
    }
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    if (_isPlaying && _audioPath != null) _audioPlayer.play(DeviceFileSource(_audioPath!));
    else _audioPlayer.stop();
    notifyListeners();
  }

  Future<void> pickAudio() async {
    FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (r != null) { _audioPath = r.files.single.path; _audioFileName = r.files.single.name; notifyListeners(); }
  }
  
  void removeAudioTrack() {
    _audioPath = null;
    _audioFileName = null;
    _audioPlayer.stop();
    notifyListeners();
  }

  // --- THE RESTORED PERSISTENCE ENGINE ---

  Future<void> saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {
      'name': _currentProjectName,
      'width': _resolution.width,
      'height': _resolution.height,
      'handIndex': _selectedHandIndex,
      'audioPath': _audioPath,
      'scenes': _scenes.map((s) => s.toJson()).toList(),
    };
    await prefs.setString('project_$_currentProjectName', jsonEncode(data));
  }

  Future<void> loadProject(String name) async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('project_$name');
    if (raw != null) {
      Map<String, dynamic> d = jsonDecode(raw);
      _currentProjectName = d['name'];
      _resolution = Size(d['width'], d['height']);
      _selectedHandIndex = d['handIndex'] ?? 0;
      _audioPath = d['audioPath'];
      _scenes = (d['scenes'] as List).map((s) => Scene.fromJson(s)).toList();
      _currentSceneIndex = 0;
      _recalculateTimestamps();
      notifyListeners();
    }
  }

  void clearWorkspace() {
    _scenes = [Scene()];
    _currentSceneIndex = 0;
    _selectedObjectId = null;
    _audioPath = null;
    _audioFileName = null;
    _audioPlayer.stop();
    _currentProjectName = "New Project ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    notifyListeners();
  }
}
