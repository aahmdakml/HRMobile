import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String? filePath; // Local path
  final String? url; // Remote URL
  final String fileName;
  final String fileType; // 'pdf', 'jpg', 'png', etc.

  const DocumentViewerScreen({
    super.key,
    this.filePath,
    this.url,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    // If we already have a local filePath, just use it
    if (widget.filePath != null) {
      setState(() {
        _localPath = widget.filePath;
        _isLoading = false;
      });
      return;
    }

    // If we have a URL, we might need to download it (especially for PDF)
    if (widget.url != null) {
      if (_isPdf) {
        // Download PDF to temp file
        try {
          final tempDir = await getTemporaryDirectory();
          final savePath = '${tempDir.path}/${widget.fileName}';

          await Dio().download(widget.url!, savePath);

          if (mounted) {
            setState(() {
              _localPath = savePath;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load document: $e';
              _isLoading = false;
            });
          }
        }
      } else {
        // For images, we can mostly use URL directly with PhotoView,
        // but let's just mark loading as done.
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'No file source provided';
        _isLoading = false;
      });
    }
  }

  bool get _isPdf => widget.fileType.toLowerCase() == 'pdf';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isPdf) {
      if (_localPath == null) return const SizedBox();
      return PDFView(
        filePath: _localPath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
          });
        },
        onPageError: (page, error) {
          // Handle page error
        },
      );
    } else {
      // Image Viewer
      ImageProvider imageProvider;
      if (widget.filePath != null) {
        imageProvider = FileImage(File(widget.filePath!));
      } else {
        imageProvider = NetworkImage(widget.url!);
      }

      return PhotoView(
        imageProvider: imageProvider,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      );
    }
  }
}
