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
  
  // Advanced Timing (Matching Benime UI)
  double delay;     // Seconds before animation starts
  double duration;  // Seconds the animation takes
  double pause;     // Seconds to wait after animation finishes
  
  Duration startTime; // Calculated automatically
  
  Color color;
  double fontSize;

  CanvasObject({
    String? id,
    required this.type,
    required this.data,
    this.pathData,
    this.x = 50.0,
    this.y = 50.0,
    this.width = 200.0,
    this.height = 100.0,
    this.delay = 0.0,
    this.duration = 2.0,
    this.pause = 0.0,
    this.startTime = Duration.zero,
    this.color = Colors.black,
    this.fontSize = 40.0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'data': data,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'delay': delay,
        'duration': duration,
        'pause': pause,
        'color': color.value,
        'fontSize': fontSize,
      };

  factory CanvasObject.fromJson(Map<String, dynamic> json) {
    ObjectType parsedType = ObjectType.values.firstWhere((e) => e.toString() == json['type']);
    return CanvasObject(
      id: json['id'],
      type: parsedType,
      data: json['data'],
      x: json['x'],
      y: json['y'],
      width: json['width'],
      height: json['height'],
      delay: (json['delay'] ?? 0.0).toDouble(),
      duration: (json['duration'] ?? 2.0).toDouble(),
      pause: (json['pause'] ?? 0.0).toDouble(),
      color: Color(json['color'] ?? Colors.black.value),
      fontSize: (json['fontSize'] ?? 40.0).toDouble(),
    );
  }
}

class Scene {
  final String id;
  List<CanvasObject> objects;
  Color backgroundColor;

  Scene({String? id, List<CanvasObject>? objects, this.backgroundColor = Colors.white})
      : id = id ?? const Uuid().v4(),
        objects = objects ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'backgroundColor': backgroundColor.value,
        'objects': objects.map((e) => e.toJson()).toList(),
      };

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'],
      backgroundColor: Color(json['backgroundColor'] ?? Colors.white.value),
      objects: (json['objects'] as List).map((e) => CanvasObject.fromJson(e)).toList(),
    );
  }
}
