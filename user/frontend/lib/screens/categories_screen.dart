import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../services/api_client.dart';
import 'card_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? domain;
  final String? title;
  final Color? themeColor;

  const CategoriesScreen({
    super.key,
    this.domain,
    this.title,
    this.themeColor,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late String? _selectedDomain;
  late Future<List<CategoryData>> _categories;

  static const Map<String, _DomainMeta> _domains = {
    'phonology': _DomainMeta(
      name: 'Phonology',
      dimension: 'Form',
      tagline: 'Smart Photo Articulation',
      color: Color(0xFF0288D1),
      bgColor: Color(0xFFE0F2FE),
      icon: Icons.record_voice_over_rounded,
    ),
    'morphology': _DomainMeta(
      name: 'Morphology',
      dimension: 'Form',
      tagline: 'Smart Flash Cards',
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFDCFCE7),
      icon: Icons.merge_type_rounded,
    ),
    'syntax': _DomainMeta(
      name: 'Syntax',
      dimension: 'Form',
      tagline: 'Syntax Stimulation Stories',
      color: Color(0xFF7B1FA2),
      bgColor: Color(0xFFF3E8FF),
      icon: Icons.menu_book_rounded,
    ),
    'semantic': _DomainMeta(
      name: 'Semantic',
      dimension: 'Content',
      tagline: 'Semantic Stimulation Cards',
      color: Color(0xFF8E24AA),
      bgColor: Color(0xFFFDF4FF),
      icon: Icons.photo_library_rounded,
    ),
    'pragmatic': _DomainMeta(
      name: 'Pragmatic',
      dimension: 'Use',
      tagline: 'Pragmatic Power Play',
      color: Color(0xFFE65100),
      bgColor: Color(0xFFFFEDD5),
      icon: Icons.sports_esports_rounded,
    ),
  };

  @override
  void initState() {
    super.initState();
    _selectedDomain = widget.domain?.toLowerCase();
    _categories = _loadCategories(_selectedDomain);
  }

  IconData _iconForName(String? iconName) {
    switch (iconName) {
      case 'pets':
        return Icons.pets;
      case 'eco':
        return Icons.eco;
      case 'directions_car':
        return Icons.directions_car;
      case 'flutter_dash':
        return Icons.flutter_dash;
      case 'restaurant':
        return Icons.restaurant;
      case 'school':
        return Icons.school;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'palette':
        return Icons.palette;
      case 'music_note':
        return Icons.music_note;
      case 'record_voice_over':
        return Icons.record_voice_over_rounded;
      case 'hearing':
        return Icons.hearing_rounded;
      case 'graphic_eq':
        return Icons.graphic_eq_rounded;
      case 'volume_up':
        return Icons.volume_up_rounded;
      case 'merge_type':
        return Icons.merge_type_rounded;
      case 'update':
        return Icons.update_rounded;
      case 'transform':
        return Icons.transform_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'alt_route':
        return Icons.alt_route_rounded;
      case 'place':
        return Icons.place_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'forum':
        return Icons.forum_rounded;
      case 'handshake':
        return Icons.handshake_rounded;
      case 'sentiment_satisfied_alt':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      case 'weekend':
        return Icons.weekend_rounded;
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'water':
        return Icons.water_rounded;
      case 'bug_report':
        return Icons.bug_report_rounded;
      case 'soup_kitchen':
        return Icons.soup_kitchen_rounded;
      case 'category':
        return Icons.category_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'toys':
        return Icons.toys_rounded;
      case 'public':
        return Icons.public_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }

  Future<List<CategoryData>> _loadCategories(String? domain) async {
    final data = await apiClient.categories(domain: domain);
    return data.map((json) {
      final dom = (json['domain'] as String? ?? 'semantic').toLowerCase();
      final meta = _domains[dom];
      final fallbackColor = meta?.bgColor ?? const Color(0xFFE8F5E9);
      final rawHex = json['color_hex'] as String?;
      final color = _parseColor(rawHex, fallbackColor);

      return CategoryData(
        id: json['id'] as int? ?? 1,
        name: (json['name_en'] ?? json['name'] ?? 'Category').toString(),
        icon: _iconForName(json['icon_name'] as String?),
        color: color,
        domain: dom,
        cardCount: json['card_count'] as int? ?? 0,
        description: (json['description'] ?? '').toString(),
      );
    }).toList();
  }

  void _onDomainSelected(String? domain) {
    setState(() {
      _selectedDomain = domain;
      _categories = _loadCategories(_selectedDomain);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMeta = _selectedDomain != null ? _domains[_selectedDomain] : null;
    final primaryColor = widget.themeColor ?? currentMeta?.color ?? const Color(0xFF8B1538);
    final appBarTitle = widget.title ??
        (currentMeta != null ? '${currentMeta.name} Categories' : 'All Categories');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: primaryColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appBarTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: primaryColor,
              ),
            ),
            if (currentMeta != null)
              Text(
                '${currentMeta.dimension} • ${currentMeta.tagline}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Domain Selector Filter Bar
          _buildDomainFilterBar(primaryColor),

          // Categories Grid
          Expanded(
            child: FutureBuilder<List<CategoryData>>(
              future: _categories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    onRetry: () => setState(() {
                      _categories = _loadCategories(_selectedDomain);
                    }),
                  );
                }
                final categories = snapshot.data ?? const <CategoryData>[];
                if (categories.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No categories found for ${_selectedDomain ?? 'this selection'}.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryCard(
                        category: category,
                        domainMeta: _domains[category.domain],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardListScreen(category: category),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainFilterBar(Color activeColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // "All" chip
            _buildDomainChip(
              label: 'All',
              isSelected: _selectedDomain == null,
              chipColor: const Color(0xFF8B1538),
              onTap: () => _onDomainSelected(null),
            ),
            const SizedBox(width: 8),

            // Form Domain chips
            ...['phonology', 'morphology', 'syntax', 'semantic', 'pragmatic']
                .map((domKey) {
              final meta = _domains[domKey]!;
              final isSelected = _selectedDomain == domKey;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildDomainChip(
                  label: '${meta.name} (${meta.dimension})',
                  icon: meta.icon,
                  isSelected: isSelected,
                  chipColor: meta.color,
                  onTap: () => _onDomainSelected(domKey),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color chipColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainMeta {
  final String name;
  final String dimension;
  final String tagline;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _DomainMeta({
    required this.name,
    required this.dimension,
    required this.tagline,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load categories.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _CategoryCard extends StatelessWidget {
  final CategoryData category;
  final _DomainMeta? domainMeta;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    this.domainMeta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = domainMeta?.color ?? const Color(0xFF4CAF50);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Domain tag badge
              if (domainMeta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: domainMeta!.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${domainMeta!.name} • ${domainMeta!.dimension}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: domainMeta!.color,
                    ),
                  ),
                ),
              // Icon container
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  category.icon,
                  size: 28,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 8),
              // Category name
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              // Explore action hint / loaded card count
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.cardCount > 0
                        ? '${category.cardCount} card${category.cardCount == 1 ? '' : 's'}'
                        : 'Browse deck',
                    style: TextStyle(
                      fontSize: 10,
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 9,
                    color: accentColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
