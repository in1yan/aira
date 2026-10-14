import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../services/api_client.dart';
import 'card_list_screen.dart';
import 'card_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String? domain;
  final String? title;
  final Color? themeColor;
  final CategoryData? parentCategory;

  const CategoriesScreen({
    super.key,
    this.domain,
    this.title,
    this.themeColor,
    this.parentCategory,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _FolderData {
  final CategoryData category;
  final List<CategoryData> subcategories;
  final List<Map<String, dynamic>> cards;
  final List<Map<String, dynamic>> breadcrumbs;

  const _FolderData({
    required this.category,
    required this.subcategories,
    required this.cards,
    required this.breadcrumbs,
  });
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late String? _selectedDomain;
  Future<List<CategoryData>>? _rootCategories;
  Future<_FolderData>? _folderContents;
  String _activeTabFilter = 'all'; // 'all', 'folders', 'cards'

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
    _selectedDomain = widget.domain?.toLowerCase() ??
        widget.parentCategory?.domain.toLowerCase();

    if (widget.parentCategory != null) {
      _folderContents = _loadFolderContents(widget.parentCategory!.id!);
    } else {
      _rootCategories = _loadRootCategories(_selectedDomain);
    }
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
        return Icons.folder_rounded;
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

  CategoryData _mapJsonToCategoryData(Map<String, dynamic> json) {
    final dom = (json['domain'] as String? ?? 'semantic').toLowerCase();
    final meta = _domains[dom];
    final fallbackColor = meta?.bgColor ?? const Color(0xFFE8F5E9);
    final rawHex = json['color_hex'] as String?;
    final color = _parseColor(rawHex, fallbackColor);

    final rawBreadcrumbs = (json['breadcrumbs'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];

    return CategoryData(
      id: json['id'] as int?,
      parentId: json['parent_id'] as int?,
      name: (json['name_en'] ?? json['name'] ?? 'Category').toString(),
      nameTa: json['name_ta'] as String?,
      nameHi: json['name_hi'] as String?,
      nameMl: json['name_ml'] as String?,
      icon: _iconForName(json['icon_name'] as String?),
      color: color,
      domain: dom,
      cardCount: json['card_count'] as int? ?? 0,
      subcategoriesCount: json['subcategories_count'] as int? ?? 0,
      totalCardCount: json['total_card_count'] as int? ?? 0,
      breadcrumbs: rawBreadcrumbs,
      description: (json['description'] ?? '').toString(),
    );
  }

  Future<List<CategoryData>> _loadRootCategories(String? domain) async {
    final data = await apiClient.categories(domain: domain, parentId: 'root');
    return data.map(_mapJsonToCategoryData).toList();
  }

  Future<_FolderData> _loadFolderContents(int folderId) async {
    try {
      final contents = await apiClient.categoryContents(folderId);
      final catData = _mapJsonToCategoryData(
          contents['category'] as Map<String, dynamic>? ?? {});
      final subcats = (contents['subcategories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_mapJsonToCategoryData)
          .toList();
      final cards = (contents['cards'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final breadcrumbs = (contents['breadcrumbs'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      return _FolderData(
        category: catData,
        subcategories: subcats,
        cards: cards,
        breadcrumbs: breadcrumbs,
      );
    } catch (_) {
      // Offline fallback: load direct subcategories and direct cards
      final subcats = await apiClient.categories(
          domain: widget.domain, parentId: folderId);
      final cards = await apiClient.cards(categoryId: folderId);
      return _FolderData(
        category: widget.parentCategory!,
        subcategories: subcats.map(_mapJsonToCategoryData).toList(),
        cards: cards,
        breadcrumbs: widget.parentCategory!.breadcrumbs,
      );
    }
  }

  void _onDomainSelected(String? domain) {
    setState(() {
      _selectedDomain = domain;
      _rootCategories = _loadRootCategories(_selectedDomain);
    });
  }

  void _navigateToCategory(CategoryData category, Color primaryColor) {
    if (category.isFolder) {
      // Navigate deeper into subfolder
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriesScreen(
            parentCategory: category,
            domain: category.domain,
            themeColor: primaryColor,
          ),
        ),
      );
    } else {
      // Navigate to card deck for leaf category
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CardListScreen(category: category),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMeta =
        _selectedDomain != null ? _domains[_selectedDomain] : null;
    final primaryColor = widget.themeColor ??
        currentMeta?.color ??
        const Color(0xFF8B1538);

    final isInsideFolder = widget.parentCategory != null;
    final appBarTitle = isInsideFolder
        ? widget.parentCategory!.name
        : (widget.title ??
            (currentMeta != null
                ? '${currentMeta.name} Categories'
                : 'All Categories'));

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
            if (isInsideFolder) ...[
              Text(
                [
                  widget.parentCategory!.nameTa,
                  widget.parentCategory!.nameHi,
                  widget.parentCategory!.nameMl,
                ].where((s) => s != null && s.isNotEmpty).join(' • '),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ] else if (currentMeta != null) ...[
              Text(
                '${currentMeta.dimension} • ${currentMeta.tagline}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
      body: isInsideFolder
          ? _buildFolderView(primaryColor)
          : _buildRootCategoriesView(primaryColor),
    );
  }

  // ---------------------------------------------------------------------------
  // ROOT VIEW (Top-level Categories & Folders)
  // ---------------------------------------------------------------------------
  Widget _buildRootCategoriesView(Color primaryColor) {
    return Column(
      children: [
        // Domain Selector Filter Bar
        _buildDomainFilterBar(primaryColor),

        // Categories Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _rootCategories = _loadRootCategories(_selectedDomain);
              });
            },
            child: FutureBuilder<List<CategoryData>>(
              future: _rootCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    onRetry: () => setState(() {
                      _rootCategories = _loadRootCategories(_selectedDomain);
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
                      childAspectRatio: 0.92,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _CategoryCard(
                        category: category,
                        domainMeta: _domains[category.domain],
                        onTap: () => _navigateToCategory(category, primaryColor),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOLDER EXPLORER VIEW (Inside a Folder / Category)
  // ---------------------------------------------------------------------------
  Widget _buildFolderView(Color primaryColor) {
    return FutureBuilder<_FolderData>(
      future: _folderContents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            onRetry: () => setState(() {
              _folderContents =
                  _loadFolderContents(widget.parentCategory!.id!);
            }),
          );
        }

        final data = snapshot.data!;
        final subcats = data.subcategories;
        final cards = data.cards;
        final breadcrumbs = data.breadcrumbs;

        final hasBoth = subcats.isNotEmpty && cards.isNotEmpty;
        final showFolders = _activeTabFilter == 'all' || _activeTabFilter == 'folders';
        final showCards = _activeTabFilter == 'all' || _activeTabFilter == 'cards';

        return Column(
          children: [
            // Breadcrumbs Trail Bar
            _buildBreadcrumbBar(breadcrumbs, primaryColor),

            // Optional Sub-filter Pills (when folder has both folders and cards)
            if (hasBoth)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildPillTab(
                      label: 'All (${subcats.length + cards.length})',
                      isSelected: _activeTabFilter == 'all',
                      color: primaryColor,
                      onTap: () => setState(() => _activeTabFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _buildPillTab(
                      label: 'Folders (${subcats.length})',
                      isSelected: _activeTabFilter == 'folders',
                      color: primaryColor,
                      onTap: () => setState(() => _activeTabFilter = 'folders'),
                    ),
                    const SizedBox(width: 8),
                    _buildPillTab(
                      label: 'Cards (${cards.length})',
                      isSelected: _activeTabFilter == 'cards',
                      color: primaryColor,
                      onTap: () => setState(() => _activeTabFilter = 'cards'),
                    ),
                  ],
                ),
              ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _folderContents =
                        _loadFolderContents(widget.parentCategory!.id!);
                  });
                },
                child: (subcats.isEmpty && cards.isEmpty)
                    ? _buildEmptyFolderState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        children: [
                          // 1. SUBFOLDERS SECTION
                          if (showFolders && subcats.isNotEmpty) ...[
                            _buildSectionHeader(
                              icon: Icons.folder_open_rounded,
                              title: 'Subfolders & Categories',
                              count: subcats.length,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.92,
                              ),
                              itemCount: subcats.length,
                              itemBuilder: (context, index) {
                                final cat = subcats[index];
                                return _CategoryCard(
                                  category: cat,
                                  domainMeta: _domains[cat.domain],
                                  onTap: () =>
                                      _navigateToCategory(cat, primaryColor),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 2. FLASHCARDS SECTION
                          if (showCards && cards.isNotEmpty) ...[
                            _buildSectionHeader(
                              icon: Icons.style_rounded,
                              title: 'Flashcards in Folder',
                              count: cards.length,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: cards.length,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return _FolderCardTile(
                                  card: card,
                                  domain: widget.parentCategory?.domain ?? 'semantic',
                                  onTap: () {
                                    final cardId = card['id'] as int? ?? 1;
                                    final rawImageUrl = (card['image_url'] ??
                                            card['trigger_image'] ??
                                            card['card_image']) as String? ??
                                        '';
                                    final imageUrl =
                                        apiClient.imageUrl(rawImageUrl);
                                    String name = (card['name'] ??
                                            card['title_en'] ??
                                            'Card')
                                        .toString()
                                        .trim();
                                    final attributes = (card['attributes_list']
                                                as List<dynamic>?)
                                            ?.whereType<Map<String, dynamic>>()
                                            .toList() ??
                                        const [];

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CardDetailScreen(
                                          cardId: cardId,
                                          cardName: name,
                                          imageUrl: imageUrl,
                                          domain: widget.parentCategory?.domain ??
                                              'semantic',
                                          cardData: card,
                                          attributes: attributes,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BREADCRUMB BAR
  // ---------------------------------------------------------------------------
  Widget _buildBreadcrumbBar(
      List<Map<String, dynamic>> breadcrumbs, Color activeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Root Domain Button
            InkWell(
              onTap: () {
                // Pop back to root category view
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.home_rounded, size: 16, color: activeColor),
                    const SizedBox(width: 4),
                    Text(
                      'Root',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 4),

            // Breadcrumb elements
            ...breadcrumbs.asMap().entries.map((entry) {
              final idx = entry.key;
              final crumb = entry.value;
              final isLast = idx == breadcrumbs.length - 1;
              final name = (crumb['name_en'] ?? crumb['name'] ?? 'Folder')
                  .toString();

              return Row(
                children: [
                  InkWell(
                    onTap: isLast
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isLast ? FontWeight.w800 : FontWeight.w600,
                          color: isLast
                              ? Colors.black87
                              : activeColor,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillTab({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFolderState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'This folder is currently empty',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No subcategories or flashcards have been created inside ${widget.parentCategory!.name} yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
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
    final isFolder = category.isFolder;

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
              // Domain tag badge or Folder badge
              if (isFolder)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_rounded,
                          size: 11, color: Color(0xFFEA580C)),
                      const SizedBox(width: 4),
                      Text(
                        '${category.subcategoriesCount} ${category.subcategoriesCount == 1 ? 'subfolder' : 'subfolders'}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                )
              else if (domainMeta != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 6),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isFolder
                      ? const Color(0xFFFFFBEB)
                      : category.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFolder
                        ? const Color(0xFFFDE68A)
                        : accentColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isFolder ? Icons.folder_rounded : category.icon,
                  size: 28,
                  color: isFolder ? const Color(0xFFD97706) : accentColor,
                ),
              ),
              const SizedBox(height: 8),

              // Category name
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),

              // Multilingual / Action Hint
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isFolder
                        ? 'Open Folder'
                        : (category.cardCount > 0
                            ? '${category.cardCount} cards'
                            : 'Browse deck'),
                    style: TextStyle(
                      fontSize: 10,
                      color: isFolder ? const Color(0xFFD97706) : accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 9,
                    color: isFolder ? const Color(0xFFD97706) : accentColor,
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

class _FolderCardTile extends StatelessWidget {
  final Map<String, dynamic> card;
  final String domain;
  final VoidCallback onTap;

  const _FolderCardTile({
    required this.card,
    required this.domain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawImageUrl = (card['image_url'] ??
            card['trigger_image'] ??
            card['card_image']) as String? ??
        '';
    final imageUrl = apiClient.imageUrl(rawImageUrl);

    String name = (card['name'] ?? card['title_en'] ?? '').toString().trim();
    if (domain.toLowerCase() == 'syntax') {
      if (name.isEmpty || name == 'Card' || name == 'Untitled Card') {
        final fileName = rawImageUrl.split('/').last.split('?').first;
        if (fileName.isNotEmpty && fileName != 'image') {
          name = fileName;
        }
      }
    }
    if (name.isEmpty) name = 'Flashcard';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_outlined,
                            size: 40, color: Color(0xFF4CAF50)),
                      )
                    : Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.broken_image_outlined,
                              size: 40, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
