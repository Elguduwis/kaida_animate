import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/canvas_object.dart';

class AnimatedDrawingWidget extends StatefulWidget {
  final CanvasObject object;
  final bool isPlaying;
  final int handIndex;

  const AnimatedDrawingWidget({
    super.key,
    required this.object,
    required this.isPlaying,
    required this.handIndex,
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
    _controller = AnimationController(vsync: this, duration: widget.object.duration);
    if (widget.isPlaying) _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedDrawingWidget old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) _controller.forward(from: 0);
    else if (!widget.isPlaying) { _controller.stop(); _controller.value = 1.0; }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

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
              color: widget.object.color,
              handIndex: widget.handIndex,
              showHand: widget.isPlaying && _controller.value < 1.0,
            ),
          );
        }
        return Opacity(
          opacity: _controller.value,
          child: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    if (widget.object.type == ObjectType.text) {
      return Text(
        widget.object.data,
        style: TextStyle(
          fontSize: widget.object.fontSize,
          color: widget.object.color,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (widget.object.type == ObjectType.image) {
      return Image.file(
        File(widget.object.data),
        width: widget.object.width,
        height: widget.object.height,
        fit: BoxFit.contain,
      );
    }
    return const SizedBox();
  }
}

class StrokeRevealPainter extends CustomPainter {
  final Path path;
  final double progress;
  final Color color;
  final int handIndex;
  final bool showHand;

  StrokeRevealPainter({required this.path, required this.progress, required this.color, required this.handIndex, required this.showHand});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final extractPath = Path();
    Offset lastPoint = Offset.zero;

    for (var metric in path.computeMetrics()) {
      final length = metric.length * progress;
      extractPath.addPath(metric.extractPath(0, length), Offset.zero);
      if (showHand) {
        final tangent = metric.getTangentForOffset(length);
        if (tangent != null) lastPoint = tangent.position;
      }
    }
    canvas.drawPath(extractPath, paint);

    if (showHand) {
      final hands = ['✍🏽', '🖐🏿', '🖊️', '🖌️', '🖍️'];
      final tp = TextPainter(
        text: TextSpan(text: hands[handIndex % hands.length], style: const TextStyle(fontSize: 40)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, lastPoint.translate(-10, -35));
    }
  }

  @override bool shouldRepaint(old) => true;
}
