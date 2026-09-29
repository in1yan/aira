import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/api_client.dart';
import 'categories_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isLoggingOut = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlayingWelcome = false;
  String? _selectedConcept; // null initially (only triad menu shown)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller =
          VideoPlayerController.asset('assets/videos/intro2.mp4');
      _videoController = controller;
      await controller.initialize();
      controller.setLooping(false);
      controller.setVolume(1.0);
      controller.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isPlayingWelcome = true;
        });
        controller.play();
      }
    } catch (e) {
      debugPrint('HomeScreen video player init error: $e');
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    final val = _videoController!.value;
    if (val.isInitialized &&
        val.position >= val.duration &&
        val.duration > Duration.zero) {
      if (_isPlayingWelcome) {
        setState(() => _isPlayingWelcome = false);
      }
    } else if (val.isPlaying != _isPlayingWelcome) {
      setState(() => _isPlayingWelcome = val.isPlaying);
    }
  }

  void _togglePlayWelcome() {
    if (_videoController == null || !_isVideoInitialized) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        _videoController!.seekTo(Duration.zero);
      }
      _videoController!.setVolume(1.0);
      _videoController!.play();
    }
  }

  void _pauseVideoIfPlaying() {
    if (_videoController != null &&
        _isVideoInitialized &&
        _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _glowController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    _pauseVideoIfPlaying();

    setState(() => _isLoggingOut = true);
    await apiClient.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      body: _currentIndex == 0 ? _buildHome() : _buildSettings(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            _pauseVideoIfPlaying();
            setState(() => _currentIndex = i);
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF8B1538).withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF8B1538)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF8B1538)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDFE),
            Color(0xFFFFF6F8),
            Color(0xFFFEEDF2),
          ],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. NIEPMD Header
                _buildHeader(),
                const SizedBox(height: 14),

                // 2. Guide Section: Video on Left + Speech Bubble on Right
                _buildHeroGuideSection(),
                const SizedBox(height: 18),

                // 3. Interactive Triad Card (Language Acquisition Device)
                _buildTriadCard(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. NIEPMD Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // NIEPMD Logo
        Image.asset(
          'assets/niepmd-logo.png',
          width: 54,
          height: 54,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B1538).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF8B1538), width: 1.5),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF8B1538),
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Organization Titles
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'राष्ट्रीय बहुदिव्यांगता जन सशक्तिकरण संस्थान',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B1538),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'National Institute for Empowerment of Persons with Multiple Disabilities',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B1538),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Text(
                    'NIEPMD',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B1538),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // App Badge 'Aira'
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF8B1538).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Text(
                      'Aira',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B1538),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quick logout / profile action
        IconButton(
          onPressed: _isLoggingOut ? null : _logout,
          tooltip: 'Logout',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF8B1538).withValues(alpha: 0.08),
            foregroundColor: const Color(0xFF8B1538),
            minimumSize: const Size(40, 40),
          ),
          icon: _isLoggingOut
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF8B1538)),
                  ),
                )
              : const Icon(Icons.logout_rounded, size: 20),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Video + Speech Bubble Section
  // ---------------------------------------------------------------------------
  Widget _buildHeroGuideSection() {
    return SizedBox(
      height: 185,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Embedded Video Player (replacing photo with intro2.mp4)
          _buildVideoPresenterCard(),
          const SizedBox(width: 10),

          // Right: Speech Bubble Card
          Expanded(
            child: _buildSpeechBubbleCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPresenterCard() {
    return GestureDetector(
      onTap: _togglePlayWelcome,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player or loading fallback
              if (_isVideoInitialized && _videoController != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width > 0
                        ? _videoController!.value.size.width
                        : 720,
                    height: _videoController!.value.size.height > 0
                        ? _videoController!.value.size.height
                        : 1280,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              else
                Container(
                  color: const Color(0xFFE8F5E9),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF8B1538)),
                    ),
                  ),
                ),

              // Overlay gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),

              // Play / Pause badge indicator
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlayingWelcome
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _isPlayingWelcome ? 'Playing' : 'Video',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubbleCard() {
    return CustomPaint(
      painter: SpeechBubblePainter(
        borderColor: const Color(0xFF8B1538),
        fillColor: Colors.white,
        borderWidth: 1.6,
        borderRadius: 18,
        arrowWidth: 9,
        arrowHeight: 14,
        arrowY: 34,
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 17,
          right: 12,
          top: 10,
          bottom: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Namaskar 🙏"
                const Text(
                  'Namaskar 🙏',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B1538),
                  ),
                ),
                const SizedBox(height: 2),

                // "Welcome to Language Acquisition Device."
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome to\n',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D47A1),
                          height: 1.15,
                        ),
                      ),
                      TextSpan(
                        text: 'Language Acquisition Device.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B1538),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                const Text(
                  'I will guide you through the application and help you understand how to use the language acquisition device.',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0288D1),
                    height: 1.25,
                  ),
                ),
              ],
            ),

            // "Play Welcome" Button
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: const Color(0xFF6B0E2A),
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                shadowColor: const Color(0xFF6B0E2A).withValues(alpha: 0.4),
                child: InkWell(
                  onTap: _togglePlayWelcome,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlayingWelcome
                              ? Icons.pause_circle_filled_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPlayingWelcome ? 'Pause Welcome' : 'Play Welcome',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Section Title Badge: Language Acquisition Device
  // ---------------------------------------------------------------------------
  Widget _buildSectionTitleBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Maroon circle with person icon
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF8B1538),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x338B1538),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),

        // Title text
        const Text(
          'Language Acquisition Device',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8B1538),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Triad Card: Content, Form, Use & Options (Semantic, Phonology, Morphology, Syntax, Pragmatic)
  // ---------------------------------------------------------------------------
  Widget _buildTriadCard() {
    return CustomPaint(
      painter: PetalDecorationPainter(
        petalColor: const Color(0xFFF8BBD0),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFF3C4D8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B1538).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: Language Acquisition Device
            _buildSectionTitleBadge(),
            const SizedBox(height: 14),

            // Inner Rounded Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF3C4D8),
                  width: 1.5,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: KeyedSubtree(
                  key: ValueKey<String>(_selectedConcept ?? 'initial_stand_alone'),
                  child: _buildConceptContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptContent() {
    // When no option is selected (initially): show only the glowing triad menu centered!
    if (_selectedConcept == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCirclesCluster(isStandalone: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1538).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8B1538).withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 15,
                    color: Color(0xFF8B1538),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tap an option to explore',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B1538),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // When Content is selected: Option on left, Circles on right (Image 1)
    if (_selectedConcept == 'content') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildContentOptions()),
          const SizedBox(width: 8),
          _buildCirclesCluster(),
        ],
      );
    }

    // When Form is selected: Circles on left, 3 Options on right (Image 0)
    if (_selectedConcept == 'form') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCirclesCluster(),
          const SizedBox(width: 8),
          Expanded(child: _buildFormOptions()),
        ],
      );
    }

    // When Use is selected: Circles on left, Pragmatic Option on right
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCirclesCluster(),
        const SizedBox(width: 8),
        Expanded(child: _buildUseOptions()),
      ],
    );
  }

  // ── Content Options (Semantic) ──
  Widget _buildContentOptions() {
    return _buildActionOptionCard(
      title: 'Semantic :',
      subtitle: 'Semantic Stimulation Cards',
      color: const Color(0xFF8E24AA),
      borderColor: const Color(0xFFCE93D8),
      bgColor: const Color(0xFFF3E5F5),
      icon: Icons.photo_library_rounded,
      onTap: () {
        _pauseVideoIfPlaying();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoriesScreen(
              domain: 'semantic',
              title: 'Semantic Categories',
              themeColor: Color(0xFF8E24AA),
            ),
          ),
        );
      },
    );
  }

  // ── Form Options (Phonology, Morphology, Syntax) ──
  Widget _buildFormOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionOptionCard(
          title: 'Phonology :',
          subtitle: 'Smart Photo Articulation',
          color: const Color(0xFF0288D1),
          borderColor: const Color(0xFF81D4FA),
          bgColor: const Color(0xFFF0F9FF),
          icon: Icons.record_voice_over_rounded,
          onTap: () {
            _pauseVideoIfPlaying();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoriesScreen(
                  domain: 'phonology',
                  title: 'Phonology Categories',
                  themeColor: Color(0xFF0288D1),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildActionOptionCard(
          title: 'Morphology :',
          subtitle: 'Smart Flash Cards',
          color: const Color(0xFF2E7D32),
          borderColor: const Color(0xFFA5D6A7),
          bgColor: const Color(0xFFF1F8E9),
          icon: Icons.merge_type_rounded,
          onTap: () {
            _pauseVideoIfPlaying();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoriesScreen(
                  domain: 'morphology',
                  title: 'Morphology Categories',
                  themeColor: Color(0xFF2E7D32),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildActionOptionCard(
          title: 'Syntax :',
          subtitle: 'Syntax Stimulation Stories',
          color: const Color(0xFF7B1FA2),
          borderColor: const Color(0xFFCE93D8),
          bgColor: const Color(0xFFF3E5F5),
          icon: Icons.menu_book_rounded,
          onTap: () {
            _pauseVideoIfPlaying();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoriesScreen(
                  domain: 'syntax',
                  title: 'Syntax Categories',
                  themeColor: Color(0xFF7B1FA2),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Use Option (Pragmatic Power Play) ──
  Widget _buildUseOptions() {
    return _buildActionOptionCard(
      title: 'Pragmatic :',
      subtitle: 'Pragmatic Power Play',
      color: const Color(0xFFE65100),
      borderColor: const Color(0xFFFFCC80),
      bgColor: const Color(0xFFFFF3E0),
      icon: Icons.sports_esports_rounded,
      onTap: () {
        _pauseVideoIfPlaying();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CategoriesScreen(
              domain: 'pragmatic',
              title: 'Pragmatic Categories',
              themeColor: Color(0xFFE65100),
            ),
          ),
        );
      },
    );
  }

  // ── Unified Option Card Widget ──
  Widget _buildActionOptionCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color borderColor,
    required Color bgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.9),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bloom & Lahey Circles Cluster (Content, Form, Use) with Glowing Animation ──
  Widget _buildCirclesCluster({bool isStandalone = false}) {
    final double circleSize = isStandalone ? 92 : 74;
    final double clusterWidth = isStandalone ? 184 : 148;
    final double clusterHeight = isStandalone ? 170 : 146;
    final isContent = _selectedConcept == 'content';
    final isForm = _selectedConcept == 'form';
    final isUse = _selectedConcept == 'use';

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowVal = _glowAnimation.value;

        return Center(
          child: SizedBox(
            width: clusterWidth,
            height: clusterHeight,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Ambient pulsating radial glow behind the triad menu
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: (isStandalone ? 160 : 126) + 16 * glowVal,
                      height: (isStandalone ? 160 : 126) + 16 * glowVal,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B1538).withValues(alpha: 0.08 * glowVal),
                            const Color(0xFFFF80AB).withValues(alpha: 0.04 * glowVal),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Content Circle (Top Left) ──
                Positioned(
                  left: 4,
                  top: 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: isStandalone ? -10 : -8,
                        top: isStandalone ? 26 : 22,
                        child: _buildRadiatingDashes(
                          color: const Color(0xFF4CAF50),
                          count: 2,
                          angle: -math.pi / 4,
                        ),
                      ),
                      _CircleActionButton(
                        size: circleSize,
                        isSelected: isContent,
                        fontSize: isStandalone ? 14 : 12,
                        glowIntensity: glowVal,
                        glowColor: const Color(0xFF4CAF50),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF43A047),
                            Color(0xFF2E7D32),
                          ],
                        ),
                        icon: _buildContentIcon(isLarge: isStandalone),
                        label: 'Content',
                        onTap: () {
                          _pauseVideoIfPlaying();
                          setState(() {
                            _selectedConcept =
                                (_selectedConcept == 'content') ? null : 'content';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // ── Form Circle (Top Right) ──
                Positioned(
                  right: 4,
                  top: 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: isStandalone ? -10 : -8,
                        top: isStandalone ? 12 : 10,
                        child: _buildRadiatingDashes(
                          color: const Color(0xFF03A9F4),
                          count: 2,
                          angle: -math.pi / 6,
                        ),
                      ),
                      _CircleActionButton(
                        size: circleSize,
                        isSelected: isForm,
                        fontSize: isStandalone ? 14 : 12,
                        glowIntensity: glowVal,
                        glowColor: const Color(0xFF03A9F4),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF29B6F6),
                            Color(0xFF0288D1),
                            Color(0xFF01579B),
                          ],
                        ),
                        icon: Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: isStandalone ? 28 : 24,
                        ),
                        label: 'Form',
                        onTap: () {
                          _pauseVideoIfPlaying();
                          setState(() {
                            _selectedConcept =
                                (_selectedConcept == 'form') ? null : 'form';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // ── Use Circle (Bottom Center - Overlapping) ──
                Positioned(
                  top: isStandalone ? 64 : 54,
                  left: isStandalone ? 46 : 37,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: -12,
                        bottom: 12,
                        child: _buildRadiatingDashes(
                          color: const Color(0xFFFF9800),
                          count: 2,
                          angle: -math.pi / 5,
                        ),
                      ),
                      Positioned(
                        right: -12,
                        bottom: 12,
                        child: _buildRadiatingDashes(
                          color: const Color(0xFFFF9800),
                          count: 2,
                          angle: math.pi / 5,
                        ),
                      ),
                      _CircleActionButton(
                        size: circleSize,
                        isSelected: isUse,
                        fontSize: isStandalone ? 14 : 12,
                        glowIntensity: glowVal,
                        glowColor: const Color(0xFFFF9800),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFB74D),
                            Color(0xFFFFA726),
                            Color(0xFFF57C00),
                          ],
                        ),
                        icon: _buildUseTapIcon(isLarge: isStandalone),
                        label: 'Use',
                        onTap: () {
                          _pauseVideoIfPlaying();
                          setState(() {
                            _selectedConcept =
                                (_selectedConcept == 'use') ? null : 'use';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // ── Hand Pointer Cursor Indicator ──
                if (isContent)
                  Positioned(
                    left: isStandalone ? 22 : 18,
                    top: isStandalone ? 58 : 48,
                    child: const _HandPointerWidget(waveColor: Color(0xFF4CAF50)),
                  ),
                if (isForm)
                  Positioned(
                    right: isStandalone ? 10 : 8,
                    top: isStandalone ? 58 : 48,
                    child: const _HandPointerWidget(waveColor: Color(0xFF03A9F4)),
                  ),
                if (isUse)
                  Positioned(
                    left: isStandalone ? 54 : 45,
                    top: isStandalone ? 116 : 96,
                    child: const _HandPointerWidget(waveColor: Color(0xFFFF9800)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentIcon({bool isLarge = false}) {
    return Container(
      width: isLarge ? 32 : 28,
      height: isLarge ? 28 : 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: isLarge ? 3 : 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Container(
            height: isLarge ? 3 : 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Container(
            height: isLarge ? 3 : 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseTapIcon({bool isLarge = false}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: isLarge ? 30 : 26,
          height: isLarge ? 30 : 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1.2,
            ),
          ),
        ),
        Icon(
          Icons.pan_tool_alt_rounded,
          color: Colors.white,
          size: isLarge ? 24 : 20,
        ),
      ],
    );
  }

  Widget _buildRadiatingDashes({
    required Color color,
    required int count,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (i) => Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Syntax Stimulation Stories Modal
  // ---------------------------------------------------------------------------
  // ignore: unused_element
  void _showSyntaxStoriesModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF7B1FA2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Syntax Stimulation Stories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                        Text(
                          'Structured sentence stories for syntactic stimulation',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stories List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildStoryCard(
                      title: 'Story 1: The Playful Puppy',
                      target: 'Target: Subject + Verb + Object (S-V-O)',
                      color: const Color(0xFF0288D1),
                      icon: Icons.pets_rounded,
                      sentences: [
                        'The puppy sees a yellow ball.',
                        'The puppy runs across the lawn.',
                        'The puppy catches the yellow ball.',
                        'The puppy drinks cool fresh milk.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStoryCard(
                      title: 'Story 2: Riya in the Garden',
                      target: 'Target: Prepositions (In, On, Under)',
                      color: const Color(0xFF43A047),
                      icon: Icons.local_florist_rounded,
                      sentences: [
                        'Riya plants a red flower in the soil.',
                        'A colorful butterfly sits on the petal.',
                        'A small brown turtle rests under the leafy tree.',
                        'The warm bright sun shines over the garden.',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStoryCard(
                      title: 'Story 3: Sharing Sweet Fruits',
                      target: 'Target: Plurals & Quantifiers',
                      color: const Color(0xFF8E24AA),
                      icon: Icons.apple_rounded,
                      sentences: [
                        'Aman washes two red apples.',
                        'He peels three sweet yellow bananas.',
                        'He places four fresh oranges into the bowl.',
                        'They enjoy the sweet fruits together happily.',
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryCard({
    required String title,
    required String target,
    required Color color,
    required IconData icon,
    required List<String> sentences,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.3),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      target,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...sentences.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final sent = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$idx',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sent,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: color, size: 18),
                    tooltip: 'Speak sentence',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Speaking: "$sent"'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pragmatic Phrases Bottom Sheet Modal
  // ---------------------------------------------------------------------------
  // ignore: unused_element
  void _showPragmaticPhrasesModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEBFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Color(0xFF673AB7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pragmatic Power Play',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                        Text(
                          'Essential phrases for everyday communication',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phrase list
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPhraseTile(
                      phrase: 'I want this',
                      purpose: 'Expressing desire / Requesting item',
                      color: const Color(0xFFFF9800),
                      icon: Icons.pan_tool_rounded,
                    ),
                    _buildPhraseTile(
                      phrase: 'Help me please',
                      purpose: 'Requesting assistance',
                      color: const Color(0xFFE91E63),
                      icon: Icons.front_hand_rounded,
                    ),
                    _buildPhraseTile(
                      phrase: 'More, please',
                      purpose: 'Continuing or repeating activity',
                      color: const Color(0xFF4CAF50),
                      icon: Icons.replay_rounded,
                    ),
                    _buildPhraseTile(
                      phrase: 'Thank you',
                      purpose: 'Social etiquette / Courtesy',
                      color: const Color(0xFF2196F3),
                      icon: Icons.favorite_rounded,
                    ),
                    _buildPhraseTile(
                      phrase: 'Look at that!',
                      purpose: 'Directing joint attention',
                      color: const Color(0xFF9C27B0),
                      icon: Icons.visibility_rounded,
                    ),
                    _buildPhraseTile(
                      phrase: 'Yes / No',
                      purpose: 'Affirming or rejecting choice',
                      color: const Color(0xFF009688),
                      icon: Icons.thumbs_up_down_rounded,
                    ),
                    _buildPhraseTile(
                      phrase: 'All done / Stop',
                      purpose: 'Concluding or ending activity',
                      color: const Color(0xFFF44336),
                      icon: Icons.stop_circle_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhraseTile({
    required String phrase,
    required String purpose,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          phrase,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Text(
          purpose,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.volume_up_rounded, color: color),
          tooltip: 'Speak phrase',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speaking: "$phrase"'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Settings Tab
  // ---------------------------------------------------------------------------
  Widget _buildSettings() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 28),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'demo@example.com',
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Enabled',
            ),
            _SettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Version 1.0.0',
            ),
            const Spacer(),
            Center(
              child: Text(
                'Aira v1.0.0 - NIEPMD',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Triad Circle Action Button
// -----------------------------------------------------------------------------
class _CircleActionButton extends StatelessWidget {
  final double size;
  final Gradient gradient;
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final double? fontSize;
  final bool isSelected;
  final double glowIntensity;
  final Color? glowColor;

  const _CircleActionButton({
    required this.size,
    required this.gradient,
    required this.icon,
    required this.label,
    required this.onTap,
    this.fontSize,
    this.isSelected = false,
    this.glowIntensity = 0.0,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? (size * 0.16);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: isSelected ? 8 : 4,
      shadowColor: Colors.black.withValues(alpha: isSelected ? 0.35 : 0.18),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            border: Border.all(
              color: Colors.white,
              width: isSelected ? 3.5 : 2.5,
            ),
            boxShadow: [
              // Glowing Animated Aura
              if (glowColor != null && glowIntensity > 0)
                BoxShadow(
                  color: glowColor!
                      .withValues(alpha: (isSelected ? 0.55 : 0.35) * glowIntensity),
                  blurRadius: (isSelected ? 18 : 12) * glowIntensity + 4,
                  spreadRadius: (isSelected ? 4 : 2) * glowIntensity + 1,
                ),
              if (isSelected)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7 * glowIntensity),
                  blurRadius: 10,
                  spreadRadius: 1.5,
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: effectiveFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Hand Pointer Widget & Painter
// -----------------------------------------------------------------------------
class _HandPointerWidget extends StatelessWidget {
  final Color waveColor;
  const _HandPointerWidget({required this.waveColor});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 38,
        height: 44,
        child: CustomPaint(
          painter: HandPointerPainter(waveColor: waveColor),
        ),
      ),
    );
  }
}

class HandPointerPainter extends CustomPainter {
  final Color waveColor;
  HandPointerPainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Concentric ripples at touch contact point (dx: 8, dy: 8)
    final ripple1 = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(const Offset(8, 8), 6, ripple1);

    final ripple2 = Paint()
      ..color = waveColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(8, 8), 11, ripple2);

    // 2. Hand pointing with blue cuff
    canvas.save();
    canvas.translate(8, 8);
    canvas.rotate(-0.35);

    final handPaint = Paint()
      ..color = const Color(0xFFFFCC80)
      ..style = PaintingStyle.fill;
    final handStroke = Paint()
      ..color = const Color(0xFFC76D25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    final handPath = Path();
    handPath.moveTo(0, 0);
    handPath.quadraticBezierTo(2, -2, 5, 0);
    handPath.lineTo(5, 14);
    handPath.lineTo(12, 14);
    handPath.quadraticBezierTo(14, 22, 11, 26);
    handPath.lineTo(-1, 26);
    handPath.quadraticBezierTo(-4, 20, -3, 15);
    handPath.lineTo(0, 13);
    handPath.close();

    canvas.drawPath(handPath, handPaint);
    canvas.drawPath(handPath, handStroke);

    // Blue sleeve at wrist
    final sleevePaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.fill;
    final sleeveStroke = Paint()
      ..color = const Color(0xFF0D47A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final sleeveRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3, 24, 15, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(sleeveRRect, sleevePaint);
    canvas.drawRRect(sleeveRRect, sleeveStroke);

    // White cuff strip
    final cuffPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, 23, 15, 3),
        const Radius.circular(1.5),
      ),
      cuffPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HandPointerPainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}

// -----------------------------------------------------------------------------
// Speech Bubble Custom Painter
// -----------------------------------------------------------------------------
class SpeechBubblePainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  final double borderRadius;
  final double arrowWidth;
  final double arrowHeight;
  final double arrowY;

  SpeechBubblePainter({
    required this.borderColor,
    required this.fillColor,
    this.borderWidth = 1.6,
    this.borderRadius = 18,
    this.arrowWidth = 9,
    this.arrowHeight = 14,
    this.arrowY = 34,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final left = arrowWidth;
    final right = size.width;
    final top = 0.0;
    final bottom = size.height;

    // Top-left after corner
    path.moveTo(left + borderRadius, top);

    // Top edge
    path.lineTo(right - borderRadius, top);
    // Top-right corner
    path.arcToPoint(
      Offset(right, top + borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Right edge
    path.lineTo(right, bottom - borderRadius);
    // Bottom-right corner
    path.arcToPoint(
      Offset(right - borderRadius, bottom),
      radius: Radius.circular(borderRadius),
    );

    // Bottom edge
    path.lineTo(left + borderRadius, bottom);
    // Bottom-left corner
    path.arcToPoint(
      Offset(left, bottom - borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Left edge up to bottom of speech bubble arrow
    path.lineTo(left, arrowY + arrowHeight);
    // Arrow tip pointing left toward the presenter video
    path.lineTo(0, arrowY + arrowHeight / 2);
    // Arrow top side back to left edge
    path.lineTo(left, arrowY);

    // Left edge up to top-left corner
    path.lineTo(left, top + borderRadius);
    // Top-left corner
    path.arcToPoint(
      Offset(left + borderRadius, top),
      radius: Radius.circular(borderRadius),
    );

    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant SpeechBubblePainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Petal / Leaf Corner Decoration Painter
// -----------------------------------------------------------------------------
class PetalDecorationPainter extends CustomPainter {
  final Color petalColor;

  PetalDecorationPainter({required this.petalColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = petalColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Top-Left Petals
    _drawPetalCluster(canvas, paint, const Offset(6, 6), 0.6);
    // Top-Right Petals
    _drawPetalCluster(canvas, paint, Offset(size.width - 6, 6), 2.5);
    // Bottom-Left Petals
    _drawPetalCluster(canvas, paint, Offset(6, size.height - 6), -0.6);
    // Bottom-Right Petals
    _drawPetalCluster(canvas, paint, Offset(size.width - 6, size.height - 6), -2.5);
  }

  void _drawPetalCluster(
      Canvas canvas, Paint paint, Offset center, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Draw 3 gentle overlapping petals
    for (int i = -1; i <= 1; i++) {
      canvas.save();
      canvas.rotate(i * 0.35);
      final path = Path();
      path.moveTo(0, 0);
      path.quadraticBezierTo(7, 10, 0, 22);
      path.quadraticBezierTo(-7, 10, 0, 0);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PetalDecorationPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Settings Tile widget
// -----------------------------------------------------------------------------
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF8B1538).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF8B1538)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        tileColor: Colors.white,
        onTap: () {},
      ),
    );
  }
}
