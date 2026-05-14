import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_quick_video_encoder/flutter_quick_video_encoder.dart';
import '../models/canvas_object.dart';

class ExportService {
  Future<String?> exportToMp4({required List<Scene> scenes, required Size videoSize, required Function(double) onProgress}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempOutputPath = '${tempDir.path}/temp_kaida.mp4';
      const int fps = 30;
      List<double> sceneStartTimes = []; List<double> sceneDurations = []; double totalDuration = 0;

      for (var scene in scenes) {
        double sceneDur = 0;
        for (var obj in scene.objects) {
          final endTime = (obj.startTime.inMilliseconds / 1000.0) + obj.duration + obj.pause;
          if (endTime > sceneDur) sceneDur = endTime;
        }
        if (sceneDur == 0) sceneDur = 2.0; sceneDur += 1.0;
        sceneStartTimes.add(totalDuration); sceneDurations.add(sceneDur); totalDuration += sceneDur;
      }

      await FlutterQuickVideoEncoder.setup(
        width: videoSize.width.toInt(), height: videoSize.height.toInt(), fps: fps,
        videoBitrate: 2500000, profileLevel: ProfileLevel.any,
        audioBitrate: 64000, audioChannels: 2, sampleRate: 44100, filepath: tempOutputPath,
      );

      final int totalFrames = (totalDuration * fps).toInt();

      for (int i = 0; i < totalFrames; i++) {
        double globalTime = i / fps; onProgress(i / totalFrames);
        int activeSceneIdx = 0;
        for (int s = 0; s < scenes.length; s++) {
          if (globalTime >= sceneStartTimes[s] && globalTime < sceneStartTimes[s] + sceneDurations[s]) { activeSceneIdx = s; break; }
        }

        Scene activeScene = scenes[activeSceneIdx];
        double sceneLocalTime = globalTime - sceneStartTimes[activeSceneIdx];

        final recorder = ui.PictureRecorder(); final canvas = ui.Canvas(recorder);
        canvas.drawRect(Rect.fromLTWH(0, 0, videoSize.width, videoSize.height), Paint()..color = activeScene.backgroundColor);

        for (var obj in activeScene.objects) {
          double objStart = obj.startTime.inMilliseconds / 1000.0;
          if (sceneLocalTime >= objStart) {
            double progress = ((sceneLocalTime - objStart) / obj.duration).clamp(0.0, 1.0);
            canvas.save(); canvas.translate(obj.x, obj.y);

            if (obj.type == ObjectType.text) {
              canvas.clipRect(Rect.fromLTWH(0, 0, obj.width * progress, obj.height));
              final textPainter = TextPainter(text: TextSpan(text: obj.data, style: TextStyle(color: obj.color, fontSize: obj.fontSize, fontWeight: FontWeight.bold)), textDirection: ui.TextDirection.ltr)..layout();
              textPainter.paint(canvas, Offset.zero);
            } else if (obj.type == ObjectType.drawing && obj.pathData != null) {
              final paint = Paint()..color = obj.color..strokeWidth = 4.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
              final partialPath = Path();
              for (ui.PathMetric metric in obj.pathData!.computeMetrics()) partialPath.addPath(metric.extractPath(0.0, metric.length * progress), Offset.zero);
              canvas.drawPath(partialPath, paint);
            }
            canvas.restore();
          }
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(videoSize.width.toInt(), videoSize.height.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) await FlutterQuickVideoEncoder.appendVideoFrame(byteData.buffer.asUint8List());
      }
      await FlutterQuickVideoEncoder.finish();
      
      // PUBLIC GALLERY EXPORT
      final publicDir = Directory('/storage/emulated/0/Movies/KAIDA_Animate');
      if (!await publicDir.exists()) await publicDir.create(recursive: true);
      final publicPath = '${publicDir.path}/kaida_export_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(tempOutputPath).copy(publicPath);
      
      onProgress(1.0);
      return publicPath;

    } catch (e) { return null; }
  }
}
