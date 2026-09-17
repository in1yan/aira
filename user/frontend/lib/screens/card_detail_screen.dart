import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'interactive_learning_screen.dart';
import 'categories_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final int? cardId;
  final String cardName;
  final String imageUrl;
  final Map<String, dynamic>? cardData;
  final List<Map<String, dynamic>> attributes;

  const CardDetailScreen({
    super.key,
    this.cardId,
    required this.cardName,
    this.imageUrl = '',
    this.cardData,
    this.attributes = const [],
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  String _selectedLanguage = 'English';
  bool _isPlayingAudio = false;
  bool _isLoading = false;
  Map<String, dynamic>? _cardData;
  List<Map<String, dynamic>> _attributesList = [];
  String _mainImageUrl = '';
  String _cardTitle = '';
  String _subcategory = '';

  final List<String> _languages = ['English', 'Tamil', 'Hindi', 'Malayalam'];

  @override
  void initState() {
    super.initState();
    _cardData = widget.cardData;
    _cardTitle = widget.cardName;
    _mainImageUrl = widget.imageUrl;

    if (_cardData != null) {
      _parseCardData(_cardData!);
    } else if (widget.attributes.isNotEmpty) {
      _attributesList = List<Map<String, dynamic>>.from(widget.attributes);
    } else if (widget.cardId != null) {
      _fetchCardDetails(widget.cardId!);
    } else {
      _fetchDefaultCard();
    }
  }

  void _parseCardData(Map<String, dynamic> data) {
    _cardTitle = (data['name'] ?? data['title_en'] ?? widget.cardName).toString();
    _subcategory = (data['subcategory'] ?? '').toString();
    _mainImageUrl = apiClient.imageUrl((data['image_url'] ?? data['trigger_image'] ?? data['card_image'] ?? widget.imageUrl) as String?);

    if (data['attributes_list'] is List && (data['attributes_list'] as List).isNotEmpty) {
      _attributesList = (data['attributes_list'] as List).whereType<Map<String, dynamic>>().toList();
    } else if (data['attributes'] is Map) {
      final map = data['attributes'] as Map<String, dynamic>;
      _attributesList = map.entries.map((e) {
        final val = e.value;
        if (val is Map<String, dynamic>) {
          return {
            'key': e.key,
            'name': val['name'] ?? val['label'] ?? e.key,
            'label': val['label'] ?? val['name'] ?? e.key,
            'image_url': val['image_url'] ?? val['attribute_image'] ?? '',
            'attribute_image': val['image_url'] ?? val['attribute_image'] ?? '',
            'value_en': val['en'] ?? val['value_en'] ?? '',
            'value_ta': val['ta'] ?? val['value_ta'] ?? '',
            'value_hi': val['hi'] ?? val['value_hi'] ?? '',
            'value_ml': val['ml'] ?? val['value_ml'] ?? '',
          };
        }
        return {'key': e.key, 'name': e.key, 'label': e.key, 'image_url': ''};
      }).toList();
    }
  }

  Future<void> _fetchCardDetails(int id) async {
    setState(() => _isLoading = true);
    try {
      final data = await apiClient.card(id);
      if (mounted) {
        setState(() {
          _cardData = data;
          _parseCardData(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDefaultCard() async {
    setState(() => _isLoading = true);
    try {
      final cards = await apiClient.cards();
      if (cards.isNotEmpty) {
        final match = cards.firstWhere(
          (c) => (c['name'] ?? c['title_en']).toString().toLowerCase() == widget.cardName.toLowerCase(),
          orElse: () => cards.first,
        );
        final fullCard = await apiClient.card(match['id'] as int? ?? 1);
        if (mounted) {
          setState(() {
            _cardData = fullCard;
            _parseCardData(fullCard);
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getLocalizedTitle() {
    if (_cardData == null) return _cardTitle;
    switch (_selectedLanguage) {
      case 'Tamil':
        final ta = _cardData!['title_ta']?.toString();
        return (ta != null && ta.isNotEmpty) ? ta : _cardTitle;
      case 'Hindi':
        final hi = _cardData!['title_hi']?.toString();
        return (hi != null && hi.isNotEmpty) ? hi : _cardTitle;
      case 'Malayalam':
        final ml = _cardData!['title_ml']?.toString();
        return (ml != null && ml.isNotEmpty) ? ml : _cardTitle;
      default:
        return _cardTitle;
    }
  }

  IconData _iconForAttribute(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('group') || lower.contains('class')) return Icons.groups_rounded;
    if (lower.contains('location') || lower.contains('habitat') || lower.contains('place')) return Icons.location_on_rounded;
    if (lower.contains('association') || lower.contains('link') || lower.contains('item')) return Icons.link_rounded;
    if (lower.contains('property') || lower.contains('properties') || lower.contains('trait')) return Icons.auto_awesome_rounded;
    if (lower.contains('use') || lower.contains('function')) return Icons.view_in_ar_rounded;
    if (lower.contains('action') || lower.contains('behavior') || lower.contains('movement')) return Icons.directions_run_rounded;
    if (lower.contains('sound') || lower.contains('voice')) return Icons.volume_up_rounded;
    if (lower.contains('food') || lower.contains('diet')) return Icons.restaurant_rounded;
    return Icons.star_rounded;
  }

  List<Map<String, dynamic>> _get6Attributes() {
    if (_attributesList.isNotEmpty) {
      // Ensure up to 6 attributes
      final list = List<Map<String, dynamic>>.from(_attributesList);
      while (list.length < 6) {
        final index = list.length + 1;
        list.add({
          'key': 'attr_$index',
          'name': 'Attribute $index',
          'label': 'Attribute $index',
          'image_url': '',
        });
      }
      return list.take(6).toList();
    }

    // Default fallback 6 attributes
    return [
      {'key': 'group', 'name': 'Group', 'label': 'Group', 'image_url': ''},
      {'key': 'location', 'name': 'Location', 'label': 'Location', 'image_url': ''},
      {'key': 'association', 'name': 'Association', 'label': 'Association', 'image_url': ''},
      {'key': 'property', 'name': 'Property', 'label': 'Property', 'image_url': ''},
      {'key': 'attr_5', 'name': 'Attribute 5', 'label': 'Attribute 5', 'image_url': ''},
      {'key': 'attr_6', 'name': 'Attribute 6', 'label': 'Attribute 6', 'image_url': ''},
    ];
  }

  void _showAttributeImageModal(Map<String, dynamic> attribute) {
    final name = (attribute['name'] ?? attribute['label'] ?? 'Attribute').toString();
    final rawImageUrl = (attribute['image_url'] ?? attribute['attribute_image'] ?? '').toString();
    final resolvedImageUrl = apiClient.imageUrl(rawImageUrl);

    String description = '';
    switch (_selectedLanguage) {
      case 'Tamil':
        description = (attribute['value_ta'] ?? attribute['ta'] ?? attribute['value_en'] ?? '').toString();
        break;
      case 'Hindi':
        description = (attribute['value_hi'] ?? attribute['hi'] ?? attribute['value_en'] ?? '').toString();
        break;
      case 'Malayalam':
        description = (attribute['value_ml'] ?? attribute['ml'] ?? attribute['value_en'] ?? '').toString();
        break;
      default:
        description = (attribute['value_en'] ?? attribute['en'] ?? '').toString();
        break;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconForAttribute(name),
                          color: const Color(0xFF2E7D32),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '$_cardTitle • Flashcard Attribute',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 24, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Uploaded Attribute Image Display
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: resolvedImageUrl.isNotEmpty
                      ? InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 3.5,
                          child: Image.network(
                            resolvedImageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                              );
                            },
                            errorBuilder: (_, __, ___) => _buildAttributeFallbackView(name),
                          ),
                        )
                      : _buildAttributeFallbackView(name),
                ),
              ),
              const SizedBox(height: 16),

              // Description Text & Audio
              if (description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final langCode = _selectedLanguage == 'Tamil'
                              ? 'ta'
                              : _selectedLanguage == 'Hindi'
                                  ? 'hi'
                                  : _selectedLanguage == 'Malayalam'
                                      ? 'ml'
                                      : 'en';
                          await apiClient.fetchTTS(description, langCode);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Speaking: $description')),
                            );
                          }
                        },
                        icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Interactive Learning Full Screen button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InteractiveLearningScreen(
                          selectedConcept: name,
                          attributeImages: {
                            for (final a in _get6Attributes())
                              (a['key'] ?? a['name'] ?? '').toString().toLowerCase():
                                  apiClient.imageUrl((a['image_url'] ?? a['attribute_image'] ?? '').toString())
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_stories_rounded, size: 20),
                  label: Text('Open Full Study Mode for $name'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttributeFallbackView(String name) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconForAttribute(name), size: 54, color: const Color(0xFF64748B)),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No custom image uploaded yet',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attributes = _get6Attributes();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    SizedBox(height: 16),
                    Text('Loading flashcard details...', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              )
            : Column(
                children: [
                  // ---- Top Bar ----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Arrow Button
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF1E293B),
                              size: 22,
                            ),
                          ),
                        ),

                        // Title: Card Identified!
                        const Text(
                          'Card Identified!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),

                        // Audio Button
                        InkWell(
                          onTap: () async {
                            setState(() => _isPlayingAudio = true);
                            final title = _getLocalizedTitle();
                            final langCode = _selectedLanguage == 'Tamil'
                                ? 'ta'
                                : _selectedLanguage == 'Hindi'
                                    ? 'hi'
                                    : _selectedLanguage == 'Malayalam'
                                        ? 'ml'
                                        : 'en';
                            await apiClient.fetchTTS(title, langCode);
                            if (mounted) {
                              setState(() => _isPlayingAudio = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Playing pronunciation: $title ($_selectedLanguage)'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isPlayingAudio ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                              color: _isPlayingAudio ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // ---- Flashcard Frame Container (Center Main Trigger Image) ----
                          Container(
                            width: double.infinity,
                            height: 260,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDDC01), // Bright yellow border
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF1E293B), width: 3),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: _mainImageUrl.isNotEmpty
                                          ? Image.network(
                                              _mainImageUrl,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (_, child, progress) {
                                                if (progress == null) return child;
                                                return const Center(
                                                  child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) => _buildFallbackCardImage(),
                                            )
                                          : _buildFallbackCardImage(),
                                    ),
                                    Positioned(
                                      top: 6,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Text(
                                          _subcategory.isNotEmpty ? _subcategory : 'Smart Flash Card',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      left: 8,
                                      child: Text(
                                        '$_cardTitle | ${_getLocalizedTitle()}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ---- Card Title ----
                          Text(
                            _getLocalizedTitle(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ---- Language Selector Pills ----
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _languages.map((lang) {
                                final isSelected = lang == _selectedLanguage;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedLanguage = lang),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.06),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      lang,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ---- 6 Concept / Attribute Buttons Grid (3 columns x 2 rows) ----
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.15,
                            children: attributes.map((attr) {
                              final name = (attr['name'] ?? attr['label'] ?? 'Attribute').toString();
                              return _buildConceptCard(
                                icon: _iconForAttribute(name),
                                label: name,
                                hasImage: (attr['image_url'] ?? attr['attribute_image'] ?? '').toString().isNotEmpty,
                                onTap: () => _showAttributeImageModal(attr),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // ---- Bottom Button: Back to Categories ----
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                                  (route) => route.isFirst,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: const Color(0xFF0F172A),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.grid_view_rounded, size: 22, color: Color(0xFF0F172A)),
                                  SizedBox(width: 10),
                                  Text(
                                    'Back to Categories',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFallbackCardImage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pets,
            size: 80,
            color: Color(0xFFD97706),
          ),
          const SizedBox(height: 6),
          Text(
            _cardTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptCard({
    required IconData icon,
    required String label,
    required bool hasImage,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? const Color(0xFF4CAF50).withOpacity(0.5) : const Color(0xFFE2E8F0),
              width: hasImage ? 1.5 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: const Color(0xFF1E293B),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasImage)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
