import 'package:flutter/material.dart';
import '../mock_data.dart';
import '../services/api_client.dart';
import 'card_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<CategoryData>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
  }

  Future<List<CategoryData>> _loadCategories() async {
    final data = await apiClient.categories();
    return data
        .map((json) => CategoryData(
              id: json['id'] as int,
              name: json['name'] as String,
              icon: Icons.category,
              color: const Color(0xFFE8F5E9),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
          title: const Text('All Categories',
              style: TextStyle(fontWeight: FontWeight.w700))),
      body: FutureBuilder<List<CategoryData>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return _ErrorState(
                onRetry: () => setState(() => _categories = _loadCategories()));
          final categories = snapshot.data ?? const <CategoryData>[];
          if (categories.isEmpty)
            return const Center(child: Text('No published categories yet.'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCard(
                    category: category,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CardListScreen(category: category))));
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not load categories.'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
}

class _CategoryCard extends StatelessWidget {
  final CategoryData category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(16)),
                  child: Icon(category.icon,
                      size: 30, color: const Color(0xFF424242))),
              const SizedBox(height: 10),
              Text(category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Browse cards',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}
