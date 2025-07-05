import 'dart:io';
import 'package:flutter/material.dart';

class ImageFrame {
  final String id;
  final File imageFile;
  final String name;
  final Offset position;
  final double scale;
  final double rotation;
  final Size size;
  final bool isLocked;
  final Color borderColor;
  final double borderWidth;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  ImageFrame({
    required this.id,
    required this.imageFile,
    required this.name,
    this.position = const Offset(100, 100),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.size = const Size(200, 200),
    this.isLocked = false,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.shadowColor,
    this.shadowBlurRadius = 5.0,
    this.shadowOffset = const Offset(2, 2),
  });

  ImageFrame copyWith({
    String? id,
    File? imageFile,
    String? name,
    Offset? position,
    double? scale,
    double? rotation,
    Size? size,
    bool? isLocked,
    Color? borderColor,
    double? borderWidth,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) {
    return ImageFrame(
      id: id ?? this.id,
      imageFile: imageFile ?? this.imageFile,
      name: name ?? this.name,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      size: size ?? this.size,
      isLocked: isLocked ?? this.isLocked,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
    );
  }
}

class CanvasProject {
  final String id;
  final String name;
  final List<ImageFrame> frames;
  final Color backgroundColor;
  final Size canvasSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  CanvasProject({
    required this.id,
    required this.name,
    this.frames = const [],
    this.backgroundColor = Colors.grey,
    this.canvasSize = const Size(1080, 1920),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  CanvasProject copyWith({
    String? id,
    String? name,
    List<ImageFrame>? frames,
    Color? backgroundColor,
    Size? canvasSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanvasProject(
      id: id ?? this.id,
      name: name ?? this.name,
      frames: frames ?? this.frames,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      canvasSize: canvasSize ?? this.canvasSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
