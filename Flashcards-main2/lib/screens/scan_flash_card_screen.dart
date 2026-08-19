import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'post_scan_categories_screen.dart';
import 'package:camera/camera.dart';

class ScanFlashCardScreen extends StatefulWidget {
  const ScanFlashCardScreen({super.key});

  @override
  State<ScanFlashCardScreen> createState() => _ScanFlashCardScreenState();
}

class _ScanFlashCardScreenState extends State<ScanFlashCardScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        _controller = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final photo = await _controller!.takePicture();
      final result = await apiClient.detect(File(photo.path));
      if (mounted) {
        setState(() => _isCapturing = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PostScanCategoriesScreen(
                imagePath: photo.path, detectionResult: result),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture or detecting card: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Scan Flash Card',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          const Spacer(flex: 1),
          // Frame
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isCapturing ? 1.0 : _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isCapturing
                        ? const Color(0xFF4CAF50)
                        : Colors.white.withOpacity(0.7),
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_isCameraInitialized && _controller != null)
                        CameraPreview(_controller!)
                      else
                        Container(
                          color: Colors.black26,
                          child: Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      // Corner decorations
                      ..._buildCorners(),
                      // Center indicator when capturing
                      if (_isCapturing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _isCapturing
                ? 'Processing...'
                : 'Place the flash card inside the frame',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isCapturing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Hold steady...',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          const Spacer(flex: 2),
          // Capture button
          GestureDetector(
            onTap: _isCapturing ? null : _onCapture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCapturing ? Colors.grey.shade700 : Colors.white,
                border: Border.all(
                  color: _isCapturing
                      ? Colors.grey.shade600
                      : Colors.white.withOpacity(0.5),
                  width: 4,
                ),
                boxShadow: _isCapturing
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Icon(
                _isCapturing ? Icons.hourglass_top : Icons.camera_alt,
                color: _isCapturing
                    ? Colors.grey.shade400
                    : const Color(0xFF1A1A2E),
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const cornerSize = 24.0;
    const cornerWidth = 3.0;
    final color = _isCapturing ? const Color(0xFF4CAF50) : Colors.white;

    return [
      // Top-left
      Positioned(
        top: -1.5,
        left: -1.5,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: cornerWidth),
              left: BorderSide(color: color, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: -1.5,
        right: -1.5,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: cornerWidth),
              right: BorderSide(color: color, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: -1.5,
        left: -1.5,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: cornerWidth),
              left: BorderSide(color: color, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: -1.5,
        right: -1.5,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: cornerWidth),
              right: BorderSide(color: color, width: cornerWidth),
            ),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
    ];
  }
}
