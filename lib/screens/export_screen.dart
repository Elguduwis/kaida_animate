import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/canvas_provider.dart';
import '../export/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  double _progress = 0.0;
  String _status = 'Initializing...';
  String? _outputPath;
  bool _isExporting = true;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    final objects = context.read<CanvasProvider>().objects;
    final exportService = ExportService();

    // Standard 720p HD format for MVP
    const Size renderSize = Size(1280, 720);

    final path = await exportService.exportToMp4(
      objects: objects,
      videoSize: renderSize,
      onProgress: (val) {
        if (!mounted) return;
        setState(() {
          _progress = val;
          if (val < 0.5) {
            _status = 'Drawing frames... ${(val * 200).toInt()}%';
          } else if (val < 1.0) {
            _status = 'Encoding MP4 Video...';
          }
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _isExporting = false;
      if (path != null) {
        _outputPath = path;
        _status = 'Export Complete!';
      } else {
        _status = 'Export Failed.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Export Video'),
        automaticallyImplyLeading: !_isExporting,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isExporting) ...[
                CircularProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  color: const Color(0xFF800080),
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please do not close the app.',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                Icon(
                  _outputPath != null ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: _outputPath != null ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_outputPath != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Saved to:\n$_outputPath',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800080),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Return to Editor'),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
