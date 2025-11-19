import 'dart:io';
import 'package:image_picker/image_picker.dart';

Future<File?> pickImageFromDevice(ImageSource source) async {
  final picker = ImagePicker();
  final XFile? picked = await picker.pickImage(
    source: source,
    imageQuality: 100,
  );
  if (picked == null) return null;
  return File(picked.path);
}

String get_image_name_from_path(String path) {
  return path.split(Platform.pathSeparator).last;
}

bool isImageFile(File file) {
  final ext = file.path.split('.').last.toLowerCase();
  return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext);
}
