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
      startTime: Duration(seconds: _objects.length), // Sequential timeline
    ));
    notifyListeners();
  }

  void addDrawingObject() {
    // MVP Preset Path (A simple star or shape to demonstrate the engine)
    Path samplePath = Path()
      ..moveTo(50, 0)
      ..lineTo(65, 35)
      ..lineTo(100, 35)
      ..lineTo(70, 55)
      ..lineTo(80, 90)
      ..lineTo(50, 70)
      ..lineTo(20, 90)
      ..lineTo(30, 55)
      ..lineTo(0, 35)
      ..lineTo(35, 35)
      ..close();

    _objects.add(CanvasObject(
      type: ObjectType.drawing,
      data: 'Sample Star',
      pathData: samplePath,
      width: 100,
      height: 100,
      startTime: Duration(seconds: _objects.length),
    ));
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
      notifyListeners();
    }
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    _selectedObjectId = null; // Deselect during playback
    notifyListeners();
    
    if (_isPlaying) {
      // Auto-stop after the longest animation finishes
      Future.delayed(const Duration(seconds: 5), () {
        if (_isPlaying) {
          _isPlaying = false;
          notifyListeners();
        }
      });
    }
  }
}
