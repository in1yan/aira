import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'home_screen.dart';

/// A screen that plays a sequence of bundled intro video clips
/// after login. Shows a progress indicator and a skip button.
///
/// Usage:
///   1. Drop your MP4 files into  assets/videos/
///   2. List them in the [videoAssets] parameter (order matters).
///
/// Example:
///   VideoIntroScreen(videoAssets: ['assets/videos/intro1.mp4', 'assets/videos/intro2.mp4'])
class VideoIntroScreen extends StatefulWidget {
  /// Ordered list of asset paths (e.g. 'assets/videos/clip1.mp4').
  final List<String> videoAssets;

  const VideoIntroScreen({super.key, required this.videoAssets});

  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen>
    with SingleTickerProviderStateMixin {
  late List<VideoPlayerController> _controllers;
  int _currentIndex = 0;
  bool _isInitialised = false;
  bool _hasError = false;

  // Animation for fade-in / cross-fade between clips
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    if (widget.videoAssets.isEmpty) {
      // No videos to play – go straight to home.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToHome());
      return;
    }

    _controllers = widget.videoAssets
        .map((path) => VideoPlayerController.asset(path))
        .toList();

    _initCurrentVideo();
  }

  Future<void> _initCurrentVideo() async {
    try {
      final controller = _controllers[_currentIndex];
      await controller.initialize();
      if (!mounted) return;

      controller.addListener(_onVideoUpdate);
      setState(() => _isInitialised = true);

      _fadeController.forward();
      controller.play();
    } catch (e) {
      debugPrint('Video init error: $e');
      // If a clip fails, skip to the next one (or go home).
      _advanceOrFinish();
    }
  }

  void _onVideoUpdate() {
    final controller = _controllers[_currentIndex];
    if (controller.value.hasError) {
      _advanceOrFinish();
      return;
    }

    // Check if the current video has ended.
    if (controller.value.isInitialized &&
        controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      _advanceOrFinish();
    }
    // Rebuild to update progress bar.
    if (mounted) setState(() {});
  }

  void _advanceOrFinish() {
    final oldController = _controllers[_currentIndex];
    oldController.removeListener(_onVideoUpdate);
    oldController.pause();

    if (_currentIndex < _controllers.length - 1) {
      // Cross-fade to the next clip.
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _isInitialised = false;
        });
        _initCurrentVideo();
      });
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final c in _controllers) {
      c.removeListener(_onVideoUpdate);
      c.dispose();
    }
    super.dispose();
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video layer ──
          if (_isInitialised)
            FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: AspectRatio(
                  aspectRatio:
                      _controllers[_currentIndex].value.aspectRatio,
                  child:
                      VideoPlayer(_controllers[_currentIndex]),
                ),
              ),
            )
          else if (!_hasError)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white70,
                strokeWidth: 2.5,
              ),
            ),

          // ── Bottom bar: progress dots + skip ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = widget.videoAssets.length;
    final progress = _videoProgress();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // ── Clip progress dots ──
          Expanded(
            child: Row(
              children: List.generate(total, (i) {
                final bool isCurrent = i == _currentIndex;
                final bool isDone = i < _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 4,
                  width: isCurrent ? 28 : 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDone
                        ? Colors.white
                        : isCurrent
                            ? Colors.white
                            : Colors.white30,
                  ),
                  child: isCurrent
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 4,
                          ),
                        )
                      : null,
                );
              }),
            ),
          ),

          const SizedBox(width: 12),

          // ── Skip button ──
          TextButton.icon(
            onPressed: _goToHome,
            icon: const Icon(Icons.skip_next_rounded,
                color: Colors.white70, size: 20),
            label: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  double _videoProgress() {
    if (!_isInitialised) return 0.0;
    final c = _controllers[_currentIndex];
    if (!c.value.isInitialized || c.value.duration == Duration.zero) {
      return 0.0;
    }
    return c.value.position.inMilliseconds / c.value.duration.inMilliseconds;
  }
}
