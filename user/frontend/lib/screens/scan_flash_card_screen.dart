import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_client.dart';
import 'card_detail_screen.dart';

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
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
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
        final controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
        if (mounted) {
          setState(() {
            _controller = controller;
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera permission/init note: $e');
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onCapture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    String cardName = 'Dog';
    String imageUrl = '';
    int? cardId;
    Map<String, dynamic>? cardData;
    List<Map<String, dynamic>> attributes = [];

    try {
      if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized) {
        try {
          final photo = await _controller!.takePicture();
          final result = await apiClient.detect(File(photo.path));
          
          if (result['card'] is Map<String, dynamic>) {
            cardData = result['card'] as Map<String, dynamic>;
            cardId = cardData['id'] as int?;
            cardName = (cardData['name'] ?? cardData['title_en'] ?? 'Dog').toString();
            imageUrl = apiClient.imageUrl(cardData['image_url'] ?? cardData['trigger_image'] ?? cardData['card_image']);
            
            if (cardData['attributes_list'] is List) {
              attributes = (cardData['attributes_list'] as List).whereType<Map<String, dynamic>>().toList();
            }
          } else {
            final detectedCardId = int.tryParse(result['card']?.toString() ?? '');
            if (detectedCardId != null) {
              final cardDetails = await apiClient.card(detectedCardId);
              cardId = detectedCardId;
              cardData = cardDetails;
              cardName = (cardDetails['name'] ?? cardDetails['title_en'] ?? 'Dog').toString();
              imageUrl = apiClient.imageUrl(cardDetails['image_url'] ?? cardDetails['trigger_image'] ?? cardDetails['card_image']);
              if (cardDetails['attributes_list'] is List) {
                attributes = (cardDetails['attributes_list'] as List).whereType<Map<String, dynamic>>().toList();
              }
            }
          }
        } catch (e) {
          debugPrint('Detection fallback: $e');
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        final defaultCard = await apiClient.card(1);
        cardId = 1;
        cardData = defaultCard;
        cardName = (defaultCard['name'] ?? defaultCard['title_en'] ?? 'Dog').toString();
        imageUrl = apiClient.imageUrl(defaultCard['image_url'] ?? defaultCard['trigger_image'] ?? defaultCard['card_image']);
        if (defaultCard['attributes_list'] is List) {
          attributes = (defaultCard['attributes_list'] as List).whereType<Map<String, dynamic>>().toList();
        }
      }
    } catch (e) {
      debugPrint('Scan capture note: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CardDetailScreen(
              cardId: cardId,
              cardName: cardName,
              imageUrl: imageUrl,
              cardData: cardData,
              attributes: attributes,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- 1. Full-Screen Camera Preview / Background ----
          if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize?.height ?? screenSize.width,
                  height: _controller!.value.previewSize?.width ?? screenSize.height,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to Scan',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap shutter button below to scan card',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // ---- 2. Vignette Mask Overlay ----
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // ---- 3. Center Scanning Frame with Laser ----
          Center(
            child: Container(
              width: screenSize.width * 0.84,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFDDC01),
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFDDC01).withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 240 * _scanLineAnimation.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withOpacity(0.9),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isCapturing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ---- 4. Top Header Bar ----
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Scan Flash Card',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- 5. Bottom Controls ----
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isCapturing ? 'Identifying Card...' : 'Align flash card inside the frame',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _onCapture,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF4CAF50),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCapturing
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF4CAF50).withOpacity(0.15),
                            ),
                            child: Icon(
                              _isCapturing ? Icons.hourglass_top : Icons.camera_alt,
                              color: _isCapturing ? Colors.white : const Color(0xFF4CAF50),
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
