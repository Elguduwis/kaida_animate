import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';

class AnimatedDrawingWidget extends StatefulWidget {
  final CanvasObject object;
  final bool isPlaying;

  const AnimatedDrawingWidget({
    super.key,
    required this.object,
    required this.isPlaying,
  });

  @override
  State<AnimatedDrawingWidget> createState() => _AnimatedDrawingWidgetState();
}

class _AnimatedDrawingWidgetState extends State<AnimatedDrawingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.object.duration,
    );

    if (widget.isPlaying) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedDrawingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.forward(from: 0.0);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
      _controller.value = 1.0; // Show full object when stopped in editor
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.object.type == ObjectType.drawing && widget.object.pathData != null) {
          return CustomPaint(
            size: Size(widget.object.width, widget.object.height),
            painter: StrokeRevealPainter(
              path: widget.object.pathData!,
              progress: _controller.value,
              showHand: widget.isPlaying && _controller.value < 1.0,
            ),
          );
        } else {
          // For Text/Images, simple fade/scale reveal
          return Opacity(
            opacity: _controller.value,
            child: child,
          );
        }
      },
      child: widget.object.type == ObjectType.text
          ? Text(
              widget.object.data,
              style: const TextStyle(fontSize: 24, color: Colors.black87, fontWeight: FontWeight.bold),
            )
          : const SizedBox(),
    );
  }
}

class StrokeRevealPainter extends CustomPainter {
  final Path path;
  final double progress;
  final bool showHand;

  StrokeRevealPainter({
    required this.path,
    required this.progress,
    required this.showHand,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path partialPath = Path();
    Offset currentPosition = Offset.zero;

    for (PathMetric metric in path.computeMetrics()) {
      final extractLength = metric.length * progress;
      partialPath.addPath(metric.extractPath(0.0, extractLength), Offset.zero);
      
      if (showHand) {
        final Tangent? tangent = metric.getTangentForOffset(extractLength);
        if (tangent != null) {
          currentPosition = tangent.position;
        }
      }
    }

    canvas.drawPath(partialPath, paint);

    // Draw the "Hand" at the exact mathematical end of the stroke
    if (showHand && progress > 0 && progress < 1) {
      final TextPainter handPainter = TextPainter(
        text: const TextSpan(text: '✍🏽', style: TextStyle(fontSize: 32)),
        textDirection: TextDirection.ltr,
      );
      handPainter.layout();
      // Offset slightly so the pen tip aligns with the stroke
      handPainter.paint(canvas, currentPosition.translate(-10, -30)); 
    }
  }

  @override
  bool shouldRepaint(covariant StrokeRevealPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.showHand != showHand;
  }
}
