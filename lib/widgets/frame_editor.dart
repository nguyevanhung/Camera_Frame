import 'package:flutter/material.dart';
import '../models/frame_data.dart';

class FrameEditor extends StatefulWidget {
  final FrameData frame;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(FrameData) onUpdate;

  const FrameEditor({
    super.key,
    required this.frame,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
  });

  @override
  State<FrameEditor> createState() => _FrameEditorState();
}

class _FrameEditorState extends State<FrameEditor> with TickerProviderStateMixin {
  late FrameData _frame;
  bool _isDragging = false;
  bool _isScaling = false;
  
  // Animation controllers
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _frame = widget.frame;
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FrameEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frame != oldWidget.frame) {
      _frame = widget.frame;
    }
    
    // Animate selection
    if (widget.isSelected && !oldWidget.isSelected) {
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
    }
  }

  void _updateFrame() {
    widget.onUpdate(_frame);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _frame.position.dx,
      top: _frame.position.dy,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _bounceAnimation.value : 1.0,
            child: Transform.rotate(
              angle: _frame.rotation,
              child: Transform.scale(
                scale: _frame.scale,
                child: GestureDetector(
                  onTap: widget.onTap,
                  onScaleStart: (details) {
                    setState(() {
                      _isScaling = true;
                    });
                  },
                  onScaleUpdate: (details) {
                    if (details.pointerCount == 1) {
                      // Single finger - drag
                      if (!_isDragging) {
                        setState(() {
                          _isDragging = true;
                        });
                      }
                      
                      setState(() {
                        _frame = _frame.copyWith(
                          position: _frame.position + details.focalPointDelta,
                        );
                      });
                    } else if (details.pointerCount == 2) {
                      // Two fingers - scale and rotate
                      final newScale = (_frame.scale * details.scale).clamp(0.5, 3.0);
                      
                      setState(() {
                        _frame = _frame.copyWith(
                          scale: newScale,
                          rotation: _frame.rotation + details.rotation * 0.1,
                        );
                      });
                    }
                  },
                  onScaleEnd: (details) {
                    setState(() {
                      _isDragging = false;
                      _isScaling = false;
                    });
                    _updateFrame();
                  },
                  child: Container(
                    width: _frame.size.width,
                    height: _frame.size.height,
                    decoration: BoxDecoration(
                      border: widget.isSelected
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDragging ? 0.3 : 0.1),
                          blurRadius: _isDragging ? 10 : 4,
                          offset: Offset(0, _isDragging ? 4 : 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _frame.imageFile,
                            width: _frame.size.width,
                            height: _frame.size.height,
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // Selection overlay
                        if (widget.isSelected) ...[
                          // Semi-transparent overlay
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue, width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          
                          // Corner handles
                          ..._buildCornerHandles(),
                          
                          // Rotation handle
                          _buildRotationHandle(),
                          
                          // Delete handle
                          _buildDeleteHandle(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCornerHandles() {
    const double handleSize = 20.0;
    const double offset = handleSize / 2;
    
    return [
      // Top-left
      Positioned(
        left: -offset,
        top: -offset,
        child: _buildHandle(handleSize, Colors.blue),
      ),
      // Top-right
      Positioned(
        right: -offset,
        top: -offset,
        child: _buildHandle(handleSize, Colors.blue),
      ),
      // Bottom-left
      Positioned(
        left: -offset,
        bottom: -offset,
        child: _buildHandle(handleSize, Colors.blue),
      ),
      // Bottom-right
      Positioned(
        right: -offset,
        bottom: -offset,
        child: _buildHandle(handleSize, Colors.blue),
      ),
    ];
  }

  Widget _buildRotationHandle() {
    return Positioned(
      right: -30,
      top: _frame.size.height / 2 - 10,
      child: _buildHandle(20.0, Colors.green),
    );
  }

  Widget _buildDeleteHandle() {
    return Positioned(
      right: -30,
      top: -30,
      child: GestureDetector(
        onTap: () {
          // Delete functionality will be handled by parent
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
