import 'package:flutter/material.dart';
import '../models/frame_model.dart';

class FrameEditor extends StatefulWidget {
  final ImageFrame frame;
  final Function(ImageFrame) onFrameChanged;
  final Function(ImageFrame) onFrameSelected;
  final Function(ImageFrame) onFrameDeleted;
  final bool isSelected;
  final Size canvasSize;

  const FrameEditor({
    super.key,
    required this.frame,
    required this.onFrameChanged,
    required this.onFrameSelected,
    required this.onFrameDeleted,
    required this.isSelected,
    required this.canvasSize,
  });

  @override
  State<FrameEditor> createState() => _FrameEditorState();
}

class _FrameEditorState extends State<FrameEditor> {
  late ImageFrame _currentFrame;
  Offset _basePosition = Offset.zero;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _currentFrame = widget.frame;
  }

  @override
  void didUpdateWidget(FrameEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame != widget.frame) {
      _currentFrame = widget.frame;
    }
  }

  void _updateFrame(ImageFrame newFrame) {
    setState(() {
      _currentFrame = newFrame;
    });
    widget.onFrameChanged(newFrame);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_currentFrame.isLocked) return;
    
    _basePosition = _currentFrame.position;
    _baseScale = _currentFrame.scale;
    _baseRotation = _currentFrame.rotation;
    
    widget.onFrameSelected(_currentFrame);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_currentFrame.isLocked) return;

    // Calculate new position based on focal point
    final newPosition = _basePosition + (details.focalPoint - details.localFocalPoint);
    
    // Constrain position within canvas bounds
    final frameWidth = _currentFrame.size.width * details.scale;
    final frameHeight = _currentFrame.size.height * details.scale;
    
    final constrainedPosition = Offset(
      newPosition.dx.clamp(0, widget.canvasSize.width - frameWidth),
      newPosition.dy.clamp(0, widget.canvasSize.height - frameHeight),
    );

    // Calculate new scale
    final newScale = (_baseScale * details.scale).clamp(0.3, 4.0);
    
    // Calculate new rotation
    final newRotation = _baseRotation + details.rotation;

    _updateFrame(_currentFrame.copyWith(
      position: constrainedPosition,
      scale: newScale,
      rotation: newRotation,
    ));
  }

  Widget _buildDeleteButton() {
    if (!widget.isSelected || _currentFrame.isLocked) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: -10,
      top: -10,
      child: GestureDetector(
        onTap: () => widget.onFrameDeleted(_currentFrame),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.red,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.close,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentFrame.position.dx,
      top: _currentFrame.position.dy,
      child: Transform.rotate(
        angle: _currentFrame.rotation,
        child: Transform.scale(
          scale: _currentFrame.scale,
          child: GestureDetector(
            onTap: () => widget.onFrameSelected(_currentFrame),
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: Container(
              width: _currentFrame.size.width,
              height: _currentFrame.size.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isSelected ? Colors.blue : _currentFrame.borderColor,
                  width: widget.isSelected ? 2 : _currentFrame.borderWidth,
                ),
                boxShadow: _currentFrame.shadowColor != null
                    ? [
                        BoxShadow(
                          color: _currentFrame.shadowColor!,
                          blurRadius: _currentFrame.shadowBlurRadius,
                          offset: _currentFrame.shadowOffset,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Image
                  ClipRect(
                    child: Image.file(
                      _currentFrame.imageFile,
                      width: _currentFrame.size.width,
                      height: _currentFrame.size.height,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Delete button
                  _buildDeleteButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
