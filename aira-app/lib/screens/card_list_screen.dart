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
  @override
  void initState() {
    super.initState();
    _cards = apiClient.cards(categoryId: widget.category.id);
  }

  List<Map<String, dynamic>> _attributeImages(Map<String, dynamic> card) {
    final rawAttributes = (card['attributes'] as List<dynamic>?) ?? const [];
    return rawAttributes
        .whereType<Map<String, dynamic>>()
        .where((attribute) => attribute['attribute_image'] != null)
        .map((attribute) => {
              'attribute_type': attribute['attribute_type'],
              'attribute_image':
                  apiClient.imageUrl(attribute['attribute_image'] as String?),
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
            title: Text(widget.category.name,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _cards,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(
                  child: Text('Could not load cards: ${snapshot.error}'));
            final cards = snapshot.data ?? const <Map<String, dynamic>>[];
            if (cards.isEmpty)
              return const Center(
                  child: Text('No published cards in this category yet.'));
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
                return _CardTile(
                    name: card['name'] as String,
                    imageUrl: apiClient.imageUrl(card['card_image'] as String?),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CardDetailScreen(
                                cardName: card['name'] as String,
                                imageUrl: apiClient
                                    .imageUrl(card['card_image'] as String?),
                                attributes: _attributeImages(card)))));
              },
            );
          },
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
