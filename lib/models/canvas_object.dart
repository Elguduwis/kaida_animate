
import 'package:uuid/uuid.dart';



enum ObjectType { text, image, svg }



class CanvasObject {

  final String id;

  final ObjectType type;

  String data; // Holds text content or file path

  double x;

  double y;

  double width;

  double height;



  CanvasObject({

    String? id,

    required this.type,

    required this.data,

    this.x = 50.0,

    this.y = 50.0,

    this.width = 100.0,

    this.height = 100.0,

  }) : id = id ?? const Uuid().v4();



  void updatePosition(double newX, double newY) {

    x = newX;

    y = newY;

  }

}

