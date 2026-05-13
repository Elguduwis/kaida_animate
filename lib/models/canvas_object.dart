import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ObjectType { text, image, drawing }

class CanvasObject {
  final String id;
  final ObjectType type;
  String data; 
  Path? pathData; 
  double x;
  double y;
  double width;
  double height;
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

  // --- SERIALIZATION ENGINE ---
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'data': data,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'startTime': startTime.inMilliseconds,
        'duration': duration.inMilliseconds,
      };

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    ObjectType parsedType = ObjectType.values.firstWhere((e) => e.toString() == json['type']);
    
    // For MVP MVP drawing persistence, we regenerate the sample path if it's a drawing
    Path? reconstructedPath;
    if (parsedType == ObjectType.drawing) {
      reconstructedPath = Path()
        ..moveTo(50, 0)..lineTo(65, 35)..lineTo(100, 35)..lineTo(70, 55)
        ..lineTo(80, 90)..lineTo(50, 70)..lineTo(20, 90)..lineTo(30, 55)
        ..lineTo(0, 35)..lineTo(35, 35)..close();
    }

    return CanvasObject(
      id: json['id'],
      type: parsedType,
      data: json['data'],
      pathData: reconstructedPath,
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      startTime: Duration(milliseconds: json['startTime']),
      duration: Duration(milliseconds: json['duration']),
    );
  }
}
