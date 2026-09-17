import 'package:flutter/material.dart';

class CategoryImageScreen extends StatelessWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? imageUrl;

  const CategoryImageScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder image area
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: categoryColor,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: imageUrl == null || imageUrl!.isEmpty
                    ? Icon(categoryIcon,
                        size: 72,
                        color: const Color(0xFF424242).withOpacity(0.6))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(categoryIcon,
                                size: 72,
                                color:
                                    const Color(0xFF424242).withOpacity(0.6))),
                      ),
              ),
              const SizedBox(height: 32),
              // Category name label
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Flash card image will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
