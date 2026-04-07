import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum OrientationMode { portrait, square, landscape, splitLandscape }

enum FrameMode { variable, uniform, polaroid, free }

enum SplitLandscapeCropMode { square, portrait }

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

  SplitLandscapeCropMode splitLandscapeCropMode = SplitLandscapeCropMode.square;

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

  void toggleSplitLandscapeCropMode() {
    splitLandscapeCropMode =
        splitLandscapeCropMode == SplitLandscapeCropMode.square
        ? SplitLandscapeCropMode.portrait
        : SplitLandscapeCropMode.square;
    notifyListeners();
  }

  Future<File?> cropImage(
    Uint8List bytes,
    int x,
    int y,
    int width,
    int height,
  ) async {
    // Use an image processing library like `image` or `flutter_image_compress`
    // to crop the image and save it as a new file.
    // This is a placeholder for the actual implementation.
    return null;
  }
}
