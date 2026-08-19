import 'dart:io';
import 'package:flutter/material.dart';
import 'category_image_screen.dart';

class PostScanCategoriesScreen extends StatelessWidget {
  final String? imagePath;
  final Map<String, dynamic>? detectionResult;

  const PostScanCategoriesScreen(
      {super.key, this.imagePath, this.detectionResult});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      label: 'Group',
      icon: Icons.group,
      color: Color(0xFFE3F2FD),
      iconColor: Color(0xFF1565C0),
    ),
    _CategoryItem(
      label: 'Association',
      icon: Icons.link,
      color: Color(0xFFF3E5F5),
      iconColor: Color(0xFF6A1B9A),
    ),
    _CategoryItem(
      label: 'Location',
      icon: Icons.location_on,
      color: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
    ),
    _CategoryItem(
      label: 'Function',
      icon: Icons.functions,
      color: Color(0xFFFFF8E1),
      iconColor: Color(0xFFF57F17),
    ),
    _CategoryItem(
      label: 'Action',
      icon: Icons.bolt,
      color: Color(0xFFFFEBEE),
      iconColor: Color(0xFFC62828),
    ),
    _CategoryItem(
      label: 'Properties',
      icon: Icons.tune,
      color: Color(0xFFE0F7FA),
      iconColor: Color(0xFF00695C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final matchedCard = detectionResult?['card'] as Map<String, dynamic>?;
    final resultText = detectionResult == null
        ? 'No scan result'
        : matchedCard == null
            ? 'No matching card found'
            : 'Matched: ${matchedCard['name']}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          'Select a Category',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Captured Photo ----
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imagePath != null
                  ? Image.file(
                      File(imagePath!),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // ---- Backend API Link Placeholder ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: Color(0xFF4CAF50), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Backend detection result:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    resultText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 12),

            // ---- 6 Resized Category Buttons ----
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _CategoryButton(
                  item: cat,
                  number: index + 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryImageScreen(
                          categoryName: cat.label,
                          categoryIcon: cat.icon,
                          categoryColor: cat.color,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}

class _CategoryButton extends StatelessWidget {
  final _CategoryItem item;
  final int number;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.item,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 18, color: item.iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$number. ${item.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
