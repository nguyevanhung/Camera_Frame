import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanner/crop_edit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      final file = File(picked.path);
      final decoded = await decodeImageFromList(await file.readAsBytes());
      final width = decoded.width.toDouble();
      final height = decoded.height.toDouble();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => CropEditScreen(
                imageFile: file,
                imgWidth: width,
                imgHeight: height,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chọn Ảnh")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(context, ImageSource.camera),
              icon: const Icon(Icons.camera),
              label: const Text("Chụp ảnh"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _pickImage(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text("Chọn ảnh từ thư viện"),
            ),
          ],
        ),
      ),
    );
  }
}
