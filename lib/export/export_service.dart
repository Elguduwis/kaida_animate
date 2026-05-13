import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import '../models/canvas_object.dart';

class ExportService {
  Future<String?> exportToMp4({
    required List<CanvasObject> objects,
    required Size videoSize,
    required Function(double) onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/kaida_export_${DateTime.now().millisecondsSinceEpoch}.mp4';

      const int fps = 30;
      double totalDuration = 0;
      for (var obj in objects) {
        final endTime = obj.startTime.inMilliseconds / 1000.0 + obj.duration.inMilliseconds / 1000.0;
        if (endTime > totalDuration) totalDuration = endTime;
      }
      
      totalDuration += 1.0; 
      final int totalFrames = (totalDuration * fps).toInt();

      // FIX: Added the missing required profileLevel parameter
      await FlutterQuickVideoEncoder.setup(
        width: videoSize.width.toInt(),
        height: videoSize.height.toInt(),
        fps: fps,
        videoBitrate: 2500000,
        profileLevel: ProfileLevel.any,
        filepath: outputPath,
      );

      for (int i = 0; i < totalFrames; i++) {
        double currentTime = i / fps;
        onProgress(i / totalFrames);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        canvas.drawRect(
          Rect.fromLTWH(0, 0, videoSize.width, videoSize.height),
          Paint()..color = Colors.white,
        );

        for (var obj in objects) {
          double objStart = obj.startTime.inMilliseconds / 1000.0;
          double objDuration = obj.duration.inMilliseconds / 1000.0;
          
          if (currentTime >= objStart) {
            double progress = ((currentTime - objStart) / objDuration).clamp(0.0, 1.0);
            
            canvas.save();
            canvas.translate(obj.x, obj.y);

            if (obj.type == ObjectType.text) {
              final textSpan = TextSpan(
                text: obj.data,
                style: TextStyle(
                  color: Colors.black.withOpacity(progress),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              );
              final textPainter = TextPainter(
                text: textSpan,
                textDirection: ui.TextDirection.ltr,
              );
              textPainter.layout();
              textPainter.paint(canvas, Offset.zero);
            } 
            else if (obj.type == ObjectType.drawing && obj.pathData != null) {
              final paint = Paint()
                ..color = Colors.black
                ..strokeWidth = 4.0
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round;

              final partialPath = Path();
              for (ui.PathMetric metric in obj.pathData!.computeMetrics()) {
                partialPath.addPath(
                  metric.extractPath(0.0, metric.length * progress),
                  Offset.zero,
                );
              }
              canvas.drawPath(partialPath, paint);
            }
            canvas.restore();
          }
        }

        final picture = recorder.endRecording();
        final image = await picture.toImage(videoSize.width.toInt(), videoSize.height.toInt());
        
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) {
          final rgbaList = byteData.buffer.asUint8List();
          await FlutterQuickVideoEncoder.appendVideoFrame(rgbaList);
        }
      }

      await FlutterQuickVideoEncoder.finish();
      onProgress(1.0);
      
      return outputPath;

    } catch (e) {
      debugPrint("Export Error: $e");
      return null;
    }
  }
}
