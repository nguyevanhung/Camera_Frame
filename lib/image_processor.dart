import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:scanner/services/image_cropper_service.dart';

// Sử dụng image_cropper thay vì native code
Future<File?> cropImageWithImageCropper(File imageFile) async {
  return await ImageCropperService.cropImageForDocument(imageFile);
}

// Helper function để convert path string thành File
Future<File?> cropImageFromPath(String imagePath) async {
  final file = File(imagePath);
  if (await file.exists()) {
    return await ImageCropperService.cropImageForDocument(file);
  }
  return null;
}

// Wrapper function để maintain compatibility
Future<File?> cropImageWithCorners(String imagePath) async {
  return await cropImageFromPath(imagePath);
}

// Không cần detect corners nữa vì image_cropper tự handle UI
// Chỉ cần function để pick và crop image
Future<File?> pickAndCropDocument() async {
  return await ImageCropperService.pickAndCropImage(
    source: ImageSource.camera,
    isDocument: true,
  );
}

Future<File?> pickFromGalleryAndCrop() async {
  return await ImageCropperService.pickAndCropImage(
    source: ImageSource.gallery,
    isDocument: true,
  );
}
