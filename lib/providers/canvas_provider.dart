import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/canvas_object.dart';

class CanvasProvider extends ChangeNotifier {
  List<CanvasObject> _objects = [];
  String? _selectedObjectId;
  bool _isPlaying = false;
  String _currentProjectName = "Draft Project";

  List<CanvasObject> get objects => _objects;
  String? get selectedObjectId => _selectedObjectId;
  bool get isPlaying => _isPlaying;
  String get currentProjectName => _currentProjectName;

  void setProjectName(String name) {
    _currentProjectName = name;
    notifyListeners();
  }

  void addTextObject(String text) {
    _objects.add(CanvasObject(type: ObjectType.text, data: text, width: 150, height: 50, duration: const Duration(seconds: 3)));
    _recalculateTimestamps();
    notifyListeners();
  }

  void addDrawingObject() {
    Path samplePath = Path()..moveTo(50, 0)..lineTo(65, 35)..lineTo(100, 35)..lineTo(70, 55)..lineTo(80, 90)..lineTo(50, 70)..lineTo(20, 90)..lineTo(30, 55)..lineTo(0, 35)..lineTo(35, 35)..close();
    _objects.add(CanvasObject(type: ObjectType.drawing, data: 'Sample Star', pathData: samplePath, width: 100, height: 100, duration: const Duration(seconds: 4)));
    _recalculateTimestamps();
    notifyListeners();
  }

  void selectObject(String? id) {
    _selectedObjectId = id;
    notifyListeners();
  }

  void updateObjectPosition(String id, double deltaX, double deltaY) {
    final objIndex = _objects.indexWhere((obj) => obj.id == id);
    if (objIndex != -1) {
      _objects[objIndex].updatePosition(_objects[objIndex].x + deltaX, _objects[objIndex].y + deltaY);
      notifyListeners();
    }
  }

  void deleteSelectedObject() {
    if (_selectedObjectId != null) {
      _objects.removeWhere((obj) => obj.id == _selectedObjectId);
      _selectedObjectId = null;
      _recalculateTimestamps();
      notifyListeners();
    }
  }

  void reorderLayers(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final CanvasObject item = _objects.removeAt(oldIndex);
    _objects.insert(newIndex, item);
    _recalculateTimestamps();
    notifyListeners();
  }

  void updateDuration(String id, int seconds) {
    final objIndex = _objects.indexWhere((obj) => obj.id == id);
    if (objIndex != -1) {
      _objects[objIndex].duration = Duration(seconds: seconds);
      _recalculateTimestamps();
      notifyListeners();
    }
  }

  void _recalculateTimestamps() {
    Duration currentStart = Duration.zero;
    for (var obj in _objects) {
      obj.startTime = currentStart;
      currentStart += obj.duration;
    }
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    _selectedObjectId = null;
    notifyListeners();
    if (_isPlaying) {
      Duration totalDuration = Duration.zero;
      for (var obj in _objects) totalDuration += obj.duration;
      Future.delayed(totalDuration, () {
        if (_isPlaying) {
          _isPlaying = false;
          notifyListeners();
        }
      });
    }
  }

  // --- PERSISTENCE ENGINE ---
  Future<void> saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = jsonEncode(_objects.map((e) => e.toJson()).toList());
    await prefs.setString('project_$_currentProjectName', jsonData);
  }

  Future<void> loadProject(String projectName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('project_$projectName');
    if (jsonData != null) {
      final List<dynamic> decoded = jsonDecode(jsonData);
      _objects = decoded.map((e) => CanvasObject.fromJson(e)).toList();
      _currentProjectName = projectName;
      _recalculateTimestamps();
      notifyListeners();
    }
  }

  void clearWorkspace() {
    _objects.clear();
    _selectedObjectId = null;
    _currentProjectName = "Draft Project ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    notifyListeners();
  }
}
