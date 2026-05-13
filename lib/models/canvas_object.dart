import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ObjectType { text, image, drawing }

class CanvasObject {
  final String id;
  final ObjectType type;
  String data; // Text content or file path
  Path? pathData; // For drawing strokes
  double x;
  double y;
  double width;
  double height;
  
  // Phase 2 Timeline Properties
  Duration startTime;
  Duration duration;

  CanvasObject({
    String? id,
    required this.type,
    required this.data,
    this.pathData,
    this.x = 50.0,
    this.y = 50.0,
    this.width = 100.0,
    this.height = 100.0,
    this.startTime = Duration.zero,
    this.duration = const Duration(seconds: 3),
  }) : id = id ?? const Uuid().v4();

  void updatePosition(double newX, double newY) {
    x = newX;
    y = newY;
  }
}
