import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/frame_data.dart';
import '../services/image_cropper_service.dart';
import '../widgets/frame_editor.dart';

class CanvasEditor extends StatefulWidget {
  const CanvasEditor({super.key});

  @override
  State<CanvasEditor> createState() => _CanvasEditorState();
}

class _CanvasEditorState extends State<CanvasEditor> with TickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();
  List<FrameData> frames = [];
  FrameData? selectedFrame;
  bool isLoading = false;
  
  // Background
  File? backgroundImage;
  Color backgroundColor = Colors.grey.shade300;
  
  // Canvas transform
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animationReset;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Reset canvas zoom/pan với animation
  void _resetCanvasTransform() {
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.reset();
    _animationController.forward();
    _animationReset!.addListener(() {
      _transformationController.value = _animationReset!.value;
    });
  }

  // Pick background image
  Future<void> _pickBackgroundImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          backgroundImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick background image: $e');
    }
  }

  // Remove background image
  void _removeBackground() {
    setState(() {
      backgroundImage = null;
      backgroundColor = Colors.grey.shade300;
    });
  }

  // Change background color
  void _changeBackgroundColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Background Color'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _backgroundColors.length,
            itemBuilder: (context, index) {
              final color = _backgroundColors[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    backgroundColor = color;
                    backgroundImage = null;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: backgroundColor == color 
                        ? Border.all(color: Colors.blue, width: 3)
                        : Border.all(color: Colors.grey.shade300),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static final List<Color> _backgroundColors = [
    Colors.white,
    Colors.grey.shade300,
    Colors.grey.shade600,
    Colors.black,
    Colors.red.shade300,
    Colors.pink.shade300,
    Colors.purple.shade300,
    Colors.blue.shade300,
    Colors.cyan.shade300,
    Colors.green.shade300,
    Colors.yellow.shade300,
    Colors.orange.shade300,
    Colors.brown.shade300,
    Colors.blueGrey.shade300,
    const Color(0xFF8E24AA),
    const Color(0xFF1976D2),
    const Color(0xFF388E3C),
    const Color(0xFFF57C00),
  ];

  Future<void> _addFrame() async {
    setState(() => isLoading = true);
    
    try {
      final File? imageFile = await ImageCropperService.pickImage(
        source: ImageSource.gallery,
      );
      
      if (imageFile != null) {
        final File? croppedFile = await ImageCropperService.cropImageForDocument(imageFile);
        
        if (croppedFile != null) {
          final newFrame = FrameData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            imageFile: croppedFile,
            position: Offset(100.w, 100.h),
            size: Size(200.w, 200.h),
            rotation: 0.0,
          );
          
          setState(() {
            frames.add(newFrame);
            selectedFrame = newFrame;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add frame: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _captureFrame() async {
    setState(() => isLoading = true);
    
    try {
      final File? imageFile = await ImageCropperService.pickImage(
        source: ImageSource.camera,
      );
      
      if (imageFile != null) {
        final File? croppedFile = await ImageCropperService.cropImageForDocument(imageFile);
        
        if (croppedFile != null) {
          final newFrame = FrameData(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            imageFile: croppedFile,
            position: Offset(50.w, 50.h),
            size: Size(200.w, 200.h),
            rotation: 0.0,
          );
          
          setState(() {
            frames.add(newFrame);
            selectedFrame = newFrame;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture frame: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _deleteSelectedFrame() {
    if (selectedFrame != null) {
      setState(() {
        frames.removeWhere((frame) => frame.id == selectedFrame!.id);
        selectedFrame = null;
      });
    }
  }

  Future<void> _exportCanvas() async {
    setState(() => isLoading = true);
    
    try {
      final RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final Directory directory = await getApplicationDocumentsDirectory();
        final String fileName = 'frame_composition_${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File('${directory.path}/$fileName');
        
        await file.writeAsBytes(pngBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: ${file.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('New Project'),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${frames.length} frames',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            height: 80.h,
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.camera_alt,
                  onTap: _captureFrame,
                ),
                _buildToolButton(
                  icon: Icons.photo_library,
                  onTap: _addFrame,
                ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.grey.shade600,
                ),
                _buildToolButton(
                  icon: Icons.palette,
                  onTap: _changeBackgroundColor,
                ),
                _buildToolButton(
                  icon: Icons.image,
                  onTap: _pickBackgroundImage,
                ),
                if (backgroundImage != null || backgroundColor != Colors.grey.shade300)
                  _buildToolButton(
                    icon: Icons.clear,
                    onTap: _removeBackground,
                  ),
                Container(
                  width: 1,
                  height: 40.h,
                  color: Colors.grey.shade600,
                ),
                _buildToolButton(
                  icon: Icons.download,
                  onTap: _exportCanvas,
                ),
                if (selectedFrame != null)
                  _buildToolButton(
                    icon: Icons.delete,
                    onTap: _deleteSelectedFrame,
                    color: Colors.red,
                  ),
              ],
            ),
          ),
          
          // Canvas
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 3.0,
                onInteractionStart: (details) {
                  // Deselect frame when interacting with canvas
                  if (selectedFrame != null) {
                    setState(() {
                      selectedFrame = null;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundImage == null ? backgroundColor : null,
                    image: backgroundImage != null
                        ? DecorationImage(
                            image: FileImage(backgroundImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Frames
                      ...frames.map((frame) => FrameEditor(
                        key: ValueKey(frame.id),
                        frame: frame,
                        isSelected: selectedFrame?.id == frame.id,
                        onTap: () {
                          setState(() {
                            selectedFrame = frame;
                          });
                        },
                        onUpdate: (updatedFrame) {
                          setState(() {
                            final index = frames.indexWhere((f) => f.id == frame.id);
                            if (index != -1) {
                              frames[index] = updatedFrame;
                            }
                          });
                        },
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetCanvasTransform,
        backgroundColor: Colors.grey.shade800,
        child: const Icon(Icons.center_focus_strong, color: Colors.white),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 48.w,
        height: 48.h,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color ?? Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }
}
