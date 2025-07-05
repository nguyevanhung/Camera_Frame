import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImageCropperService {
  static final ImageCropper _imageCropper = ImageCropper();
  static final ImagePicker _imagePicker = ImagePicker();

  // Pick image from camera or gallery
  static Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Crop image with document scanner style
  static Future<File?> cropImageForDocument(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatio: null, // Free aspect ratio for document scanning
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            showCropGrid: true,
            hideBottomControls: false,
            cropFrameColor: Colors.blue,
            cropGridColor: Colors.blue.withOpacity(0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
            activeControlsWidgetColor: Colors.blue,
          ),
          IOSUiSettings(
            title: 'Crop Document',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: false,
            rectX: 0,
            rectY: 0,
            rectWidth: 0,
            rectHeight: 0,
            showActivitySheetOnDone: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  // Crop image with custom aspect ratio
  static Future<File?> cropImageWithAspectRatio(
    File imageFile, {
    CropAspectRatioPreset? aspectRatio,
    bool lockAspectRatio = false,
  }) async {
    try {
      final CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatio: aspectRatio != null 
          ? _getAspectRatio(aspectRatio)
          : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: aspectRatio ?? CropAspectRatioPreset.original,
            lockAspectRatio: lockAspectRatio,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            showCropGrid: true,
            hideBottomControls: false,
            cropFrameColor: Colors.blue,
            cropGridColor: Colors.blue.withOpacity(0.5),
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: lockAspectRatio,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  // Helper method to convert CropAspectRatioPreset to CropAspectRatio
  static CropAspectRatio? _getAspectRatio(CropAspectRatioPreset preset) {
    switch (preset) {
      case CropAspectRatioPreset.square:
        return const CropAspectRatio(ratioX: 1, ratioY: 1);
      case CropAspectRatioPreset.ratio3x2:
        return const CropAspectRatio(ratioX: 3, ratioY: 2);
      case CropAspectRatioPreset.ratio4x3:
        return const CropAspectRatio(ratioX: 4, ratioY: 3);
      case CropAspectRatioPreset.ratio16x9:
        return const CropAspectRatio(ratioX: 16, ratioY: 9);
      default:
        return null;
    }
  }

  // Pick and crop image in one step
  static Future<File?> pickAndCropImage({
    required ImageSource source,
    CropAspectRatioPreset? aspectRatio,
    bool lockAspectRatio = false,
    bool isDocument = false,
  }) async {
    try {
      // Pick image first
      final File? pickedImage = await pickImage(source: source);
      if (pickedImage == null) return null;

      // Crop image
      if (isDocument) {
        return await cropImageForDocument(pickedImage);
      } else {
        return await cropImageWithAspectRatio(
          pickedImage,
          aspectRatio: aspectRatio,
          lockAspectRatio: lockAspectRatio,
        );
      }
    } catch (e) {
      debugPrint('Error in pickAndCropImage: $e');
      return null;
    }
  }
}
