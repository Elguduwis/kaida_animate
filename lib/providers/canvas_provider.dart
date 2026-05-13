
import 'package:flutter/material.dart';

import '../models/canvas_object.dart';



class CanvasProvider extends ChangeNotifier {

  final List<CanvasObject> _objects = [];

  String? _selectedObjectId;



  List<CanvasObject> get objects => _objects;

  String? get selectedObjectId => _selectedObjectId;



  void addTextObject(String text) {

    _objects.add(CanvasObject(

      type: ObjectType.text,

      data: text,

      width: 150,

      height: 50,

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

}

