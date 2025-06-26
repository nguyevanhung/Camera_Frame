import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CropEditScreen extends StatefulWidget {
  final File imageFile;
  final double imgWidth;
  final double imgHeight;

  const CropEditScreen({
    super.key,
    required this.imageFile,
    required this.imgWidth,
    required this.imgHeight,
  });

  @override
  State<CropEditScreen> createState() => _CropEditScreenState();
}

class _CropEditScreenState extends State<CropEditScreen> {
  late List<Offset> _corners;
  Uint8List? _croppedBytes;

  double _imageScale = 1.0;
  Offset _imageOffset = Offset.zero;
  bool _isCropping = true;

  @override
  void initState() {
    super.initState();
    _corners = [
      const Offset(0, 0),
      Offset(widget.imgWidth, 0),
      Offset(widget.imgWidth, widget.imgHeight),
      Offset(0, widget.imgHeight),
    ];
  }

  Future<void> _cropImage() async {
    const channel = MethodChannel('frameit/detect_corners');
    final result = await channel.invokeMethod<Uint8List>('cropImage', {
      'path': widget.imageFile.path,
      'points':
          _corners.map((e) => {'x': e.dx.toInt(), 'y': e.dy.toInt()}).toList(),
    });

    setState(() {
      _croppedBytes = result;
      _isCropping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa ảnh"),
        actions: [
          if (_isCropping)
            TextButton(
              onPressed: _cropImage,
              child: const Text(
                "Xác nhận",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = constraints.maxWidth;
                final boxHeight = constraints.maxHeight;
                final scale =
                    (widget.imgWidth == 0 || widget.imgHeight == 0)
                        ? 1.0
                        : (boxWidth / widget.imgWidth).clamp(
                          0.0,
                          boxHeight / widget.imgHeight,
                        );

                final imgDisplayWidth = widget.imgWidth * scale;
                final imgDisplayHeight = widget.imgHeight * scale;
                final offset = Offset(
                  (boxWidth - imgDisplayWidth) / 2,
                  (boxHeight - imgDisplayHeight) / 2,
                );

                _imageScale = scale;
                _imageOffset = offset;

                return Stack(
                  children: [
                    Positioned(
                      left: offset.dx,
                      top: offset.dy,
                      width: imgDisplayWidth,
                      height: imgDisplayHeight,
                      child:
                          _croppedBytes == null
                              ? Image.file(widget.imageFile, fit: BoxFit.fill)
                              : Image.memory(_croppedBytes!, fit: BoxFit.fill),
                    ),
                    if (_isCropping && _croppedBytes == null) ...[
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CropOverlayPainter(
                            points:
                                _corners
                                    .map((e) => e * scale + offset)
                                    .toList(),
                          ),
                        ),
                      ),
                      ..._corners.asMap().entries.map((entry) {
                        final index = entry.key;
                        final point = entry.value * scale + offset;
                        return Positioned(
                          left: point.dx - 12,
                          top: point.dy - 12,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                final local =
                                    (point + details.delta - offset) / scale;
                                _corners[index] = Offset(
                                  local.dx.clamp(0, widget.imgWidth),
                                  local.dy.clamp(0, widget.imgHeight),
                                );
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final List<Offset> points;
  CropOverlayPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;

    final paint =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 3;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(points[i], points[(i + 1) % 4], paint);
    }

    final dotPaint = Paint()..color = Colors.red;
    for (final p in points) {
      canvas.drawCircle(p, 8, dotPaint);
      canvas.drawCircle(
        p,
        10,
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
