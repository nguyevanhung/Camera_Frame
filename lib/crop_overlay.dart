import 'package:flutter/material.dart';

class CropOverlay extends StatefulWidget {
  final List<Offset> corners;
  final ValueChanged<List<Offset>> onCornerDrag;

  const CropOverlay({
    super.key,
    required this.corners,
    required this.onCornerDrag,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  late List<Offset> _points;

  @override
  void initState() {
    super.initState();
    _points = List.from(widget.corners);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onPanUpdate: (details) {
          for (int i = 0; i < _points.length; i++) {
            if ((details.localPosition - _points[i]).distance < 30) {
              setState(() {
                _points[i] = details.localPosition;
              });
              widget.onCornerDrag(_points);
              break;
            }
          }
        },
        child: CustomPaint(painter: _CropPainter(points: _points)),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final List<Offset> points;

  _CropPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine =
        Paint()
          ..color = Colors.green
          ..strokeWidth = 3;

    final paintDot =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    if (points.length == 4) {
      canvas.drawLine(points[0], points[1], paintLine);
      canvas.drawLine(points[1], points[2], paintLine);
      canvas.drawLine(points[2], points[3], paintLine);
      canvas.drawLine(points[3], points[0], paintLine);

      for (final p in points) {
        canvas.drawCircle(p, 10, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) => true;
}
