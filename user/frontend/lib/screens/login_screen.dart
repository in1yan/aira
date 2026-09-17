import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'home_screen.dart';

class DemoPersona {
  final String name;
  final String role;
  final String email;
  final String password;
  final IconData icon;
  final Color color;
  final String description;

  const DemoPersona({
    required this.name,
    required this.role,
    required this.email,
    required this.password,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  int _selectedPersonaIndex = 0;
  int _tabIndex = 0; // 0 = Demo Personas & 1-Tap Login, 1 = Custom Credentials

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  static const List<DemoPersona> _demoPersonas = [
    DemoPersona(
      name: 'Alex Rivera',
      role: 'Student Learner',
      email: 'alex.student@aira.ai',
      password: 'student123',
      icon: Icons.school_rounded,
      color: Color(0xFF4CAF50),
      description: 'Practice cards, audio pronunciation, & interactive quiz',
    ),
    DemoPersona(
      name: 'Sarah Chen',
      role: 'Educator / Teacher',
      email: 'sarah.teacher@aira.ai',
      password: 'teacher123',
      icon: Icons.psychology_rounded,
      color: Color(0xFF2196F3),
      description: 'Explore flashcard decks, multi-languages, & object scan',
    ),
    DemoPersona(
      name: 'Sam Taylor',
      role: 'Guest Explorer',
      email: 'guest.sam@aira.ai',
      password: 'guest123',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFFFA000),
      description: 'Instant sandbox access with preloaded sample data',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
    _applyPersona(_demoPersonas[0]);
  }

  void _applyPersona(DemoPersona persona) {
    _emailController.text = persona.email;
    _passwordController.text = persona.password;
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginCustom() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await apiClient.login(email, password);
      if (!mounted) return;
      _navigateToHome();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to connect to server. Falling back to offline mode.');
      _navigateToHome();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loginDemo(DemoPersona persona) async {
    setState(() => _isSubmitting = true);
    try {
      await apiClient.loginAsDemo(
        email: persona.email,
        name: persona.name,
        role: persona.role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Logged in as ${persona.name} (${persona.role})'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1800),
        ),
      );
      _navigateToHome();
    } catch (_) {
      _showError('Failed to initialize demo session.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePersona = _demoPersonas[_selectedPersonaIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // ---- Header Logo & Brand ----
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Aira Flashcards',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-Powered Multilingual Visual Learning',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Demo Mode Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFFBC02D), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.stars_rounded,
                                  size: 16, color: Color(0xFFF57F17)),
                              SizedBox(width: 6),
                              Text(
                                'Interactive Demo Sandbox Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---- Main Card ----
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFDDC01),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mode Switcher Tabs
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tabIndex = 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _tabIndex == 0
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _tabIndex == 0
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.flash_on_rounded,
                                          size: 17,
                                          color: _tabIndex == 0
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Demo Profiles',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: _tabIndex == 0
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _tabIndex == 0
                                                ? const Color(0xFF2E7D32)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _tabIndex = 1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _tabIndex == 1
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _tabIndex == 1
                                          ? [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.badge_outlined,
                                          size: 17,
                                          color: _tabIndex == 1
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Custom Login',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: _tabIndex == 1
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _tabIndex == 1
                                                ? const Color(0xFF2E7D32)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_tabIndex == 0) ...[
                          // Section Title
                          Row(
                            children: [
                              const Text(
                                'Select Demo Persona',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '1-Tap Access',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Persona Cards
                          ...List.generate(_demoPersonas.length, (index) {
                            final persona = _demoPersonas[index];
                            final isSelected = _selectedPersonaIndex == index;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedPersonaIndex = index);
                                  _applyPersona(persona);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? persona.color.withValues(alpha: 0.08)
                                        : const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? persona.color
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? persona.color
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          persona.icon,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  persona.name,
                                                  style: const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF212121),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: persona.color
                                                        .withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    persona.role,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: persona.color,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              persona.description,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.grey.shade600,
                                                height: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: persona.color,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 8),

                          // Quick 1-Tap Login Button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _loginDemo(activePersona),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activePersona.color,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.rocket_launch_rounded,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Launch Demo as ${activePersona.name.split(' ').first}',
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ] else ...[
                          // Custom credentials form
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'e.g. user@aira.ai',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF9FAF9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAF9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4CAF50),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  _applyPersona(_demoPersonas[0]);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Demo credentials filled!'),
                                      duration: Duration(milliseconds: 1000),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.auto_fix_high_rounded,
                                    size: 16),
                                label: const Text(
                                  'Autofill Demo',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF388E3C),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'In demo mode, any password works or switch to Demo Profiles tab.',
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _loginCustom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Text(
                                      'Login / Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---- Demo Features Pill Showcase ----
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_awesome,
                                size: 16, color: Color(0xFF4CAF50)),
                            SizedBox(width: 6),
                            Text(
                              'Demo Capabilities Included',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _FeatureChip(
                              icon: Icons.camera_alt_outlined,
                              label: 'AI Card Scan',
                            ),
                            _FeatureChip(
                              icon: Icons.record_voice_over_outlined,
                              label: '4-Lang TTS',
                            ),
                            _FeatureChip(
                              icon: Icons.wifi_off_outlined,
                              label: 'Offline Mock Fallback',
                            ),
                            _FeatureChip(
                              icon: Icons.quiz_outlined,
                              label: 'Interactive Quiz',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }
}
