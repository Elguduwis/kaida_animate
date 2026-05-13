import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/canvas_object.dart';

class CanvasProvider extends ChangeNotifier {
  List<CanvasObject> _objects = [];
  String? _selectedObjectId;
  bool _isPlaying = false;
  String _currentProjectName = "Draft Project";
  
  // Audio Mixer State
  String? _audioPath;
  String? _audioFileName;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<CanvasObject> get objects => _objects;
  String? get selectedObjectId => _selectedObjectId;
  bool get isPlaying => _isPlaying;
  String get currentProjectName => _currentProjectName;
  String? get audioFileName => _audioFileName;

  void setProjectName(String name) {
    _currentProjectName = name;
    notifyListeners();
  }

  // --- AUDIO MIXER ENGINE ---
  Future<void> pickAudioTrack() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      _audioPath = result.files.single.path!;
      _audioFileName = result.files.single.name;
      notifyListeners();
    }
  }

  void removeAudioTrack() {
    _audioPath = null;
    _audioFileName = null;
    _audioPlayer.stop();
    notifyListeners();
  }

  // --- CANVAS OPERATIONS ---
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

  void togglePlay() async {
    _isPlaying = !_isPlaying;
    _selectedObjectId = null;
    notifyListeners();
    
    if (_isPlaying) {
      // Sync audio playback with animation preview
      if (_audioPath != null) {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      }

      Duration totalDuration = Duration.zero;
      for (var obj in _objects) totalDuration += obj.duration;
      
      Future.delayed(totalDuration, () {
        if (_isPlaying) {
          _isPlaying = false;
          _audioPlayer.stop(); // Stop audio when animation ends
          notifyListeners();
        }
      });
    } else {
      await _audioPlayer.stop(); // Stop audio if manually paused
    }
  }

  // --- PERSISTENCE ENGINE WITH AUDIO SUPPORT ---
  Future<void> saveProject() async {
    final prefs = await SharedPreferences.getInstance();
    
    Map<String, dynamic> projectData = {
      'audioPath': _audioPath,
      'audioFileName': _audioFileName,
      'objects': _objects.map((e) => e.toJson()).toList(),
    };
    
    final String jsonData = jsonEncode(projectData);
    await prefs.setString('project_$_currentProjectName', jsonData);
  }

  Future<void> loadProject(String projectName) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString('project_$projectName');
    
    if (jsonData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonData);
        
        // Load Audio state
        _audioPath = decoded['audioPath'];
        _audioFileName = decoded['audioFileName'];
        
        // Load Objects
        final List<dynamic> objectsList = decoded['objects'] ?? [];
        _objects = objectsList.map((e) => CanvasObject.fromJson(e)).toList();
        
        _currentProjectName = projectName;
        _recalculateTimestamps();
        notifyListeners();
      } catch (e) {
        // Fallback for older projects saved as a direct list
        final List<dynamic> decodedList = jsonDecode(jsonData);
        _objects = decodedList.map((e) => CanvasObject.fromJson(e)).toList();
        _audioPath = null;
        _audioFileName = null;
        _currentProjectName = projectName;
        _recalculateTimestamps();
        notifyListeners();
      }
    }
  }

  void clearWorkspace() {
    _objects.clear();
    _selectedObjectId = null;
    _audioPath = null;
    _audioFileName = null;
    _audioPlayer.stop();
    _currentProjectName = "Draft Project ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    notifyListeners();
  }
}
