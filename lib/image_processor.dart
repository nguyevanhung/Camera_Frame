import 'package:flutter/services.dart';

const MethodChannel _platform = MethodChannel('frameit/detect_corners');

Future<List<Offset>> detectCorners(String imagePath) async {
  final result = await _platform.invokeMethod<List<dynamic>>('detectCorners', {
    'path': imagePath,
  });

  return result!.map((e) {
    final map = Map<String, dynamic>.from(e);
    return Offset(map['x'].toDouble(), map['y'].toDouble());
  }).toList();
}

Future<Uint8List?> cropImageWithCorners(
  String imagePath,
  List<Offset> corners,
) async {
  final result = await _platform.invokeMethod<Uint8List>('cropImage', {
    'path': imagePath,
    'points':
        corners.map((e) => {'x': e.dx.toInt(), 'y': e.dy.toInt()}).toList(),
  });
  return result;
}
