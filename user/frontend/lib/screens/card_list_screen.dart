import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../services/api_client.dart';
import 'card_detail_screen.dart';

class CardListScreen extends StatefulWidget {
  final CategoryData category;
  const CardListScreen({super.key, required this.category});
  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  late Future<List<Map<String, dynamic>>> _cards;
  static const Map<String, String> _domainLabels = {
    'phonology': 'Form • Phonology Articulation',
    'morphology': 'Form • Morphology Flash Cards',
    'syntax': 'Form • Syntax Stimulation Stories',
    'semantic': 'Content • Semantic Stimulation Cards',
    'pragmatic': 'Use • Pragmatic Power Play',
  };

  @override
  void initState() {
    super.initState();
    _cards = apiClient.cards(
      categoryId: widget.category.id,
      domain: widget.category.domain,
    );
  }

  Future<void> _refreshCards() async {
    setState(() {
      _cards = apiClient.cards(
        categoryId: widget.category.id,
        domain: widget.category.domain,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              if (_domainLabels.containsKey(widget.category.domain.toLowerCase()))
                Text(
                  _domainLabels[widget.category.domain.toLowerCase()]!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshCards,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _cards,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load cards: ${snapshot.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refreshCards,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final cards = snapshot.data ?? const <Map<String, dynamic>>[];
              if (cards.isEmpty) {
                return Center(
                  child: ListView(
                    shrinkWrap: true,
                    children: const [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No published cards in this category yet.'),
                        ),
                      ),
                    ],
                  ),
                );
              }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final cardId = card['id'] as int? ?? 1;
                final name = (card['name'] ?? card['title_en'] ?? 'Card').toString();
                final imageUrl = apiClient.imageUrl((card['image_url'] ?? card['trigger_image'] ?? card['card_image']) as String?);
                final attributes = (card['attributes_list'] as List<dynamic>?)?.whereType<Map<String, dynamic>>().toList() ?? const [];

                return _CardTile(
                    name: name,
                    imageUrl: imageUrl,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CardDetailScreen(
                                cardId: cardId,
                                cardName: name,
                                imageUrl: imageUrl,
                                domain: widget.category.domain,
                                cardData: card,
                                attributes: attributes))));
              },
            );
          },
        ),
      ),
    );
  }

class _CardTile extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  const _CardTile(
      {required this.name, required this.imageUrl, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Expanded(
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.image_outlined,
                          size: 48, color: Color(0xFF4CAF50))
                      : Image.network(imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48)),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            )),
      );
}
