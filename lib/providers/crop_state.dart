import 'dart:io';
import 'package:flutter/material.dart';

enum OrientationMode { portrait, square, landscape }

enum FrameMode { variable, uniform, polaroid, free }

class CropImage {
  final File file;
  CropImage(this.file);
}

class CropState with ChangeNotifier {
  OrientationMode orientation = OrientationMode.portrait;
  FrameMode frame = FrameMode.uniform;
  Color borderColor = Colors.white;
  Color backgroundColor = Colors.black;
  double borderThickness = 32.0;
  double borderThickness2 = 32.0;
  double cornerRadius = 0.0;
  double dividerThickness = 4.0;
  bool darkMode = true;
  bool showGrid = false;
  bool roundedCorners = false;
  String watermarkText = '';
  TextStyle watermarkStyle = const TextStyle(
    color: Colors.white70,
    fontSize: 20,
  );

  final List<File> _images = [];

  List<File> get images => List.unmodifiable(_images);

  void setOrientation(OrientationMode m) {
    orientation = m;
    notifyListeners();
  }

  void setFrame(FrameMode f) {
    frame = f;
    notifyListeners();
  }

  void setBorderColor(Color c) {
    borderColor = c;
    notifyListeners();
  }

  void setBackgroundColor(Color c) {
    backgroundColor = c;
    notifyListeners();
  }

  void setBorderThickness(double t) {
    borderThickness = t;
    notifyListeners();
  }

  // For frames that require a second thickness value
  // e.g., thickHorizontal or thickVertical
  void setBorderThickness2(double t) {
    borderThickness2 = t;
    notifyListeners();
  }

  void addImage(File image) {
    if (images.length >= 4) {
      return;
    }
    _images.add(image);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final image = _images.removeAt(oldIndex);
    _images.insert(newIndex, image);
    notifyListeners();
  }

  void setDividerThickness(double t) {
    dividerThickness = t;
    notifyListeners();
  }

  void removeImage(File image) {
    _images.remove(image);
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void toggleGrid() {
    showGrid = !showGrid;
    notifyListeners();
  }

  void setWatermark(String s) {
    watermarkText = s;
    notifyListeners();
  }

  void setWatermarkStyle(TextStyle s) {
    watermarkStyle = s;
    notifyListeners();
  }

  void toggleRoundedCorners() {
    roundedCorners = !roundedCorners;
    notifyListeners();
  }

  void setCornerRadius(double r) {
    cornerRadius = r;
    notifyListeners();
  }
}
