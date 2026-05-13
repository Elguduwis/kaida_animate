import 'package:flutter/material.dart';
import '../models/canvas_object.dart';

class CanvasProvider extends ChangeNotifier {
  final List<CanvasObject> _objects = [];
  String? _selectedObjectId;
  bool _isPlaying = false;

  List<CanvasObject> get objects => _objects;
  String? get selectedObjectId => _selectedObjectId;
  bool get isPlaying => _isPlaying;

  void addTextObject(String text) {
    _objects.add(CanvasObject(
      type: ObjectType.text,
      data: text,
      width: 150,
      height: 50,
      duration: const Duration(seconds: 3),
    ));
    _recalculateTimestamps();
    notifyListeners();
  }

  void addDrawingObject() {
    Path samplePath = Path()
      ..moveTo(50, 0)..lineTo(65, 35)..lineTo(100, 35)..lineTo(70, 55)
      ..lineTo(80, 90)..lineTo(50, 70)..lineTo(20, 90)..lineTo(30, 55)
      ..lineTo(0, 35)..lineTo(35, 35)..close();

    _objects.add(CanvasObject(
      type: ObjectType.drawing,
      data: 'Sample Star',
      pathData: samplePath,
      width: 100,
      height: 100,
      duration: const Duration(seconds: 4),
    ));
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
      _objects[objIndex].updatePosition(
        _objects[objIndex].x + deltaX,
        _objects[objIndex].y + deltaY,
      );
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

  // NEW: Layer Ordering System
  void reorderLayers(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final CanvasObject item = _objects.removeAt(oldIndex);
    _objects.insert(newIndex, item);
    _recalculateTimestamps();
    notifyListeners();
  }

  // NEW: Duration Adjustment
  void updateDuration(String id, int seconds) {
    final objIndex = _objects.indexWhere((obj) => obj.id == id);
    if (objIndex != -1) {
      _objects[objIndex].duration = Duration(seconds: seconds);
      _recalculateTimestamps();
      notifyListeners();
    }
  }

  // Automatically sequence objects so they animate one after the other
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
      // Calculate total video time based on all layers
      Duration totalDuration = Duration.zero;
      for (var obj in _objects) {
        totalDuration += obj.duration;
      }
      
      Future.delayed(totalDuration, () {
        if (_isPlaying) {
          _isPlaying = false;
          notifyListeners();
        }
      });
    }
  }
}
