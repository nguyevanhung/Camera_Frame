import 'dart:io';

import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/core/models/editor_callbacks/pro_image_editor_callbacks.dart';
import 'package:pro_image_editor/features/main_editor/main_editor.dart';
import 'package:scanner/widget/custom_appbar_widget.dart';
import 'package:scanner/widget/custom_navbar_widget.dart';

void main() => runApp(
  DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder:
          (context, child) => MaterialApp(
            useInheritedMediaQuery: true,
            builder: DevicePreview.appBuilder,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          ),
    ); //222
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditScreen(imageFile: File(picked.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 80.h,
                    child: ElevatedButton(
                      onPressed: () {
                        _pickImage(context, ImageSource.camera);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.zero,
                        elevation: 4,
                        backgroundColor: const Color.fromARGB(
                          173,
                          155,
                          69,
                          246,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 28.sp,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "Camera",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => _pickImage(context, ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 28.sp,
                            color: Colors.white,
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            "Album",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 26.h),
            Text(
              "Dự án:",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: 0,
        onItemTapped: (p0) {},
      ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final File imageFile;
  const EditScreen({super.key, required this.imageFile});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  File? _imageFile;
  List<Offset> _corners = [];
  Uint8List? _croppedBytes;
  int _selectedFilter = 0;
  int _rotation = 0;
  double _imageScale = 1.0;
  Offset _imageOffset = Offset.zero;
  double _imgWidth = 1;
  double _imgHeight = 1;
  bool _isCropping = false;
  bool _showFilters = false;

  // Biến hỗ trợ kéo mượt
  Offset? _cornerStart;

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Gốc', 'filter': null},
    {
      'name': 'Grayscale',
      'filter': const ColorFilter.matrix([
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
    },
    {
      'name': 'Sepia',
      'filter': const ColorFilter.matrix([
        0.393,
        0.769,
        0.189,
        0,
        0,
        0.349,
        0.686,
        0.168,
        0,
        0,
        0.272,
        0.534,
        0.131,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
    },
    {
      'name': 'Invert',
      'filter': const ColorFilter.matrix([
        -1,
        0,
        0,
        0,
        255,
        0,
        -1,
        0,
        0,
        255,
        0,
        0,
        -1,
        0,
        255,
        0,
        0,
        0,
        1,
        0,
      ]),
    },
    {
      'name': 'Vintage',
      'filter': const ColorFilter.matrix([
        0.6,
        0.3,
        0.1,
        0,
        0,
        0.2,
        0.7,
        0.1,
        0,
        0,
        0.2,
        0.1,
        0.7,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
    },
    {
      'name': 'Cold',
      'filter': const ColorFilter.matrix([
        1.0,
        0,
        0,
        0,
        -10,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        1.2,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
    },
    {
      'name': 'Warm',
      'filter': const ColorFilter.matrix([
        1.2,
        0,
        0,
        0,
        0,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        0.8,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initImage();
  }

  Future<void> _initImage() async {
    final file = widget.imageFile;
    final decoded = await decodeImageFromList(await file.readAsBytes());
    final width = decoded.width.toDouble();
    final height = decoded.height.toDouble();

    // Thay vì sát mép, lấy vào trong 10% mỗi cạnh
    final marginX = width * 0.1;
    final marginY = height * 0.1;

    setState(() {
      _imageFile = file;
      _imgWidth = width;
      _imgHeight = height;
      _corners = [
        Offset(marginX, marginY),
        Offset(width - marginX, marginY),
        Offset(width - marginX, height - marginY),
        Offset(marginX, height - marginY),
      ];
      _croppedBytes = null;
      _isCropping = false;
    });
  }

  Future<void> _cropImage() async {
    if (_imageFile == null || _corners.length != 4) return;

    setState(() {
      _isCropping = true;
    });

    try {
      const channel = MethodChannel('frameit/detect_corners');
      final result = await channel.invokeMethod<Uint8List>('cropImage', {
        'path': _imageFile!.path,
        'points':
            _corners
                .map((e) => {'x': e.dx.toInt(), 'y': e.dy.toInt()})
                .toList(),
      });

      setState(() {
        _croppedBytes = result;
      });
    } catch (e) {
      debugPrint("Error cropping image: $e");
    } finally {
      setState(() {
        _isCropping = false;
      });
    }
  }

  Widget _buildFilterSelector(Uint8List imageBytes) {
    return Container(
      height: 120.h,
      color: Colors.black87,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = index == _selectedFilter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },
            child: Container(
              width: 80.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
              child: Column(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: ColorFiltered(
                        colorFilter:
                            filter['filter'] as ColorFilter? ??
                            const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                        child: Image.memory(imageBytes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    filter['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.white,
                      fontSize: 10.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes =
        _croppedBytes ??
        (_imageFile != null ? _imageFile!.readAsBytesSync() : null);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        elevation: 5,
        actions: [
          if (_isCropping)
            Padding(
              padding: EdgeInsets.all(12.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 60.w, maxHeight: 80.h),
                child: ElevatedButton(
                  onPressed: _cropImage,
                  child: Text(
                    "Xong",
                    style: TextStyle(fontSize: 12.sp, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 6.h,
                      horizontal: 12.w,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            if (_imageFile != null)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final boxWidth = constraints.maxWidth;
                            final boxHeight = constraints.maxHeight;
                            final scale =
                                (_imgWidth == 0 || _imgHeight == 0)
                                    ? 1.0
                                    : (boxWidth / _imgWidth).clamp(
                                      0.0,
                                      boxHeight / _imgHeight,
                                    );
                            final imgDisplayWidth = _imgWidth * scale;
                            final imgDisplayHeight = _imgHeight * scale;
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
                                  child: Transform.rotate(
                                    angle:
                                        (_rotation * 90) * 3.1415926535 / 180,
                                    child: ColorFiltered(
                                      colorFilter:
                                          _filters[_selectedFilter]['filter']
                                              as ColorFilter? ??
                                          const ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.dst,
                                          ),
                                      child:
                                          _croppedBytes == null
                                              ? Image.file(
                                                _imageFile!,
                                                fit: BoxFit.fill,
                                              )
                                              : Image.memory(
                                                _croppedBytes!,
                                                fit: BoxFit.fill,
                                              ),
                                    ),
                                  ),
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
                                      left: point.dx - 20.w,
                                      top: point.dy - 20.h,
                                      child: GestureDetector(
                                        onPanStart: (details) {
                                          _cornerStart = _corners[index];
                                        },
                                        onPanUpdate: (details) {
                                          setState(() {
                                            final delta =
                                                details.delta / _imageScale;
                                            _corners[index] = Offset(
                                              (_cornerStart!.dx + delta.dx)
                                                  .clamp(0, _imgWidth),
                                              (_cornerStart!.dy + delta.dy)
                                                  .clamp(0, _imgHeight),
                                            );
                                          });
                                        },
                                        onPanEnd: (_) {
                                          _cornerStart = null;
                                        },
                                        child: Container(
                                          width: 40.w,
                                          height: 40.h,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            shape: BoxShape.circle,
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
                      if (_showFilters && imageBytes != null)
                        _buildFilterSelector(imageBytes),
                      buildBottomToolBar(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomToolBar() {
    final tools = [
      {'icon': Icons.crop, 'label': 'Crop'},
      {'icon': Icons.filter, 'label': 'Filter'},
      {'icon': Icons.rotate_right, 'label': 'Rotate'},
      {'icon': Icons.brightness_6, 'label': 'Light'},
      {'icon': Icons.tune, 'label': 'Adjust'},
      {'icon': Icons.mode_edit_outline_sharp, 'label': 'edit'},
    ];

    return Container(
      color: const Color.fromARGB(255, 28, 27, 26),
      height: 100.h,
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      alignment: Alignment.topCenter,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return GestureDetector(
            onTap: () async {
              if (tool['label'] == 'Crop') {
                setState(() {
                  _isCropping = true;
                  _croppedBytes = null;
                  _showFilters = false;
                });
              } else if (tool['label'] == 'Filter') {
                setState(() {
                  _showFilters = !_showFilters;
                  _isCropping = false;
                });
              } else if (tool['label'] == 'Rotate') {
                setState(() {
                  _rotation = (_rotation + 1) % 4;
                });
              } else if (tool['label'] == 'edit') {
                if (_imageFile != null) {
                  Uint8List imageBytes =
                      _croppedBytes ?? await _imageFile!.readAsBytes();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ProImageEditor.memory(
                            imageBytes,
                            callbacks: ProImageEditorCallbacks(
                              onImageEditingComplete: (
                                Uint8List editedBytes,
                              ) async {
                                setState(() {
                                  _croppedBytes = editedBytes;
                                });
                                Navigator.pop(context);
                                return;
                              },
                            ),
                          ),
                    ),
                  );
                }
              } else if (tool['label'] == 'Adjust') {
                if (_imageFile != null) {
                  Uint8List imageBytes =
                      _croppedBytes ?? await _imageFile!.readAsBytes();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageEditor(image: imageBytes),
                    ),
                  );
                  if (result != null && result is Uint8List) {
                    setState(() {
                      _croppedBytes = result;
                    });
                  }
                }
              }
            },

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black12,
                  radius: 28.r,
                  child: Icon(
                    tool['icon'] as IconData,
                    size: 26.sp,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  tool['label'] as String,
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
          );
        },
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
          ..strokeWidth = 3.w;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(points[i], points[(i + 1) % 4], paint);
    }

    final dotPaint =
        Paint()
          ..color = const Color.fromARGB(255, 238, 229, 228)
          ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 8.r, dotPaint);
      canvas.drawCircle(
        p,
        10.r,
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.w,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
