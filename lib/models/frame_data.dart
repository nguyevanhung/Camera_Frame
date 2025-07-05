import 'dart:io';
import 'package:flutter/material.dart';

class FrameData {
  final String id;
  final File imageFile;
  final Offset position;
  final Size size;
  final double rotation;
  final double scale;

  FrameData({
    required this.id,
    required this.imageFile,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  FrameData copyWith({
    String? id,
    File? imageFile,
    Offset? position,
    Size? size,
    double? rotation,
    double? scale,
  }) {
    return FrameData(
      id: id ?? this.id,
      imageFile: imageFile ?? this.imageFile,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrameData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FrameData{id: $id, position: $position, size: $size, rotation: $rotation, scale: $scale}';
  }
}
