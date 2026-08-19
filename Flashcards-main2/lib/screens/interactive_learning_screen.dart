import 'package:flutter/material.dart';
import '../mock_data.dart';

class InteractiveLearningScreen extends StatefulWidget {
  final String selectedConcept;

  const InteractiveLearningScreen({
    super.key,
    required this.selectedConcept,
  });

  @override
  State<InteractiveLearningScreen> createState() =>
      _InteractiveLearningScreenState();
}

class _InteractiveLearningScreenState extends State<InteractiveLearningScreen>
    with SingleTickerProviderStateMixin {
  late String _currentConcept;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _currentConcept = widget.selectedConcept;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchConcept(String concept) {
    _animController.reverse().then((_) {
      setState(() => _currentConcept = concept);
      _animController.forward();
    });
  }

  // Map concept names to icons
  IconData _iconFor(String concept) {
    final match = dogConcepts.where((c) => c.concept == concept);
    return match.isNotEmpty ? match.first.icon : Icons.info;
  }

  // Map concept names to colors
  Color _colorFor(String concept) {
    switch (concept) {
      case 'Group':
        return const Color(0xFF4CAF50);
      case 'Use':
        return const Color(0xFFE91E63);
      case 'Action':
        return const Color(0xFFFF9800);
      case 'Properties':
        return const Color(0xFF9C27B0);
      case 'Location':
        return const Color(0xFF2196F3);
      case 'Association':
        return const Color(0xFF009688);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final explanation =
        conceptExplanations[_currentConcept] ?? 'No explanation available.';
    final conceptValue =
        dogConcepts.where((c) => c.concept == _currentConcept).first.value;
    final color = _colorFor(_currentConcept);

    // Other concepts for bottom chips (exclude current)
    final otherConcepts =
        dogConcepts.where((c) => c.concept != _currentConcept).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          _currentConcept,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Concept badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconFor(_currentConcept),
                              size: 16, color: color),
                          const SizedBox(width: 8),
                          Text(
                            _currentConcept,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Large image placeholder
                    Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.7),
                            color.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _iconFor(_currentConcept),
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            conceptValue,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Explanation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 20,
                                color: Color(0xFF4CAF50),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Learn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            explanation,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Color(0xFF424242),
                            ),
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
          // ---- Bottom concept chips ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Explore More',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: otherConcepts.map((c) {
                      final chipColor = _colorFor(c.concept);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Material(
                          color: chipColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _switchConcept(c.concept),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    c.icon,
                                    size: 18,
                                    color: chipColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.concept,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: chipColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
