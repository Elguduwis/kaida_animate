import 'dart:convert';
import 'dart:io';
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
  
  // Project Settings
  Size _resolution = const Size(1280, 720); // Default YouTube
  int _selectedHandIndex = 0; // 0 to 4 (5 options)

  // Audio
  String? _audioPath;
  String? _audioFileName;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Getters
  List<Scene> get scenes => _scenes;
  int get currentSceneIndex => _currentSceneIndex;
  Scene get currentScene => _scenes[_currentSceneIndex];
  Size get resolution => _resolution;
  int get selectedHandIndex => _selectedHandIndex;
  String? get audioFileName => _audioFileName;
  bool get isPlaying => _isPlaying;
  String get currentProjectName => _currentProjectName;
  String? get selectedObjectId => _selectedObjectId;

  void selectScene(int index) {
    _currentSceneIndex = index;
    _selectedObjectId = null;
    notifyListeners();
  }

  void addScene() {
    _scenes.add(Scene());
    _currentSceneIndex = _scenes.length - 1;
    notifyListeners();
  }

  void deleteScene(int index) {
    if (_scenes.length > 1) {
      _scenes.removeAt(index);
      if (_currentSceneIndex >= _scenes.length) _currentSceneIndex = _scenes.length - 1;
      notifyListeners();
    }
  }

  void updateResolution(Size res) {
    _resolution = res;
    notifyListeners();
  }

  void setHand(int index) {
    _selectedHandIndex = index;
    notifyListeners();
  }

  void updateSceneColor(Color color) {
    currentScene.backgroundColor = color;
    notifyListeners();
  }

  // --- OBJECT OPERATIONS ---
  void addObject(CanvasObject obj) {
    currentScene.objects.add(obj);
    _recalculateTimestamps();
    notifyListeners();
  }

  void selectObject(String? id) {
    _selectedObjectId = id;
    notifyListeners();
  }

  void updateObjectPosition(String id, double dx, double dy) {
    final idx = currentScene.objects.indexWhere((o) => o.id == id);
    if (idx != -1) {
      currentScene.objects[idx].x += dx;
      currentScene.objects[idx].y += dy;
      notifyListeners();
    }
  }

  void reorderObjects(int oldIdx, int newIdx) {
    if (oldIdx < newIdx) newIdx -= 1;
    final obj = currentScene.objects.removeAt(oldIdx);
    currentScene.objects.insert(newIdx, obj);
    _recalculateTimestamps();
    notifyListeners();
  }

  void _recalculateTimestamps() {
    for (var scene in _scenes) {
      Duration start = Duration.zero;
      for (var obj in scene.objects) {
        obj.startTime = start;
        start += obj.duration;
      }
    }
  }

  // --- AUDIO ---
  Future<void> pickAudio() async {
    FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (r != null) {
      _audioPath = r.files.single.path;
      _audioFileName = r.files.single.name;
      notifyListeners();
    }
  }

  // --- PERSISTENCE ---
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

  void togglePlay() {
    _isPlaying = !_isPlaying;
    if (_isPlaying && _audioPath != null) {
       _audioPlayer.play(DeviceFileSource(_audioPath!));
    } else {
       _audioPlayer.stop();
    }
    notifyListeners();
  }
}
