import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ObjectType { text, image, drawing }

class CanvasObject {
  final String id;
  final ObjectType type;
  String data; // Text content or file path
  Path? pathData; 
  double x;
  double y;
  double width;
  double height;
  Duration startTime;
  Duration duration;
  
  // Style Properties
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
    this.startTime = Duration.zero,
    this.duration = const Duration(seconds: 3),
    this.color = Colors.black,
    this.fontSize = 24.0,
  }) : id = id ?? const Uuid().v4();

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
      startTime: Duration(milliseconds: json['startTime']),
      duration: Duration(milliseconds: json['duration']),
      color: Color(json['color'] ?? Colors.black.value),
      fontSize: (json['fontSize'] ?? 24.0).toDouble(),
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
