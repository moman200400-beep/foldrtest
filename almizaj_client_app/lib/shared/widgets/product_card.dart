import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:almizaj_client_app/features/products/product_details_screen.dart';
import 'package:almizaj_client_app/features/products/favorites_provider.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String Function(String) getImageUrl;
  final VoidCallback onAddToCart;
  final String? searchQuery;

  const ProductCard({
    super.key,
    required this.product,
    required this.getImageUrl,
    required this.onAddToCart,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = (product['stock'] ?? 0) <= 0;
    final bool hasDiscount = product['discount_price'] != null &&
        product['discount_price'].toString().isNotEmpty &&
        product['discount_price'].toString() != 'null';

    final String productId = product['id'].toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: product,
              getImageUrl: getImageUrl,
            ),
          ),
        );
      },
      child: GlassContainer(
        borderRadius: 20,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── الصورة مع الأيقونات ──
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Hero(
                      tag: 'product_image_$productId',
                      child: Image.network(
                        getImageUrl(product['img']?.toString() ?? ''),
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  // شارة الخصم
                  if (hasDiscount)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'عرض خاص',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                  // زر المفضلة
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favs, _) {
                        final isFav = favs.isFavorite(productId);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            favs.toggle(productId);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isFav
                                  ? const Color(0xFFEF4444)
                                  : Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.white : Colors.white,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── معلومات المنتج ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(product['name']?.toString() ?? '', searchQuery ?? ''),
                  const SizedBox(height: 6),
                  if (hasDiscount)
                    Row(children: [
                      Text(
                        '${product['discount_price']} ر.س',
                        style: const TextStyle(
                          color: Color(0xFFEC4899),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${product['price']}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ])
                  else
                    Text(
                      '${product['price']} ر.س',
                      style: const TextStyle(
                        color: Color(0xFFEC4899),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: outOfStock
                            ? null
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFEC4899),
                                  Color(0xFFA855F7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                      child: ElevatedButton(
                        onPressed: outOfStock ? null : onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: outOfStock
                              ? Colors.grey.shade300
                              : Colors.transparent,
                          foregroundColor:
                              outOfStock ? Colors.grey : Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          outOfStock ? 'نفد المخزون' : 'أضف للسلة',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 400.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    const styleNormal = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, fontFamily: 'Tajawal');
    if (query.trim().isEmpty) {
      return Text(text, style: styleNormal, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    
    final int exactMatch = text.toLowerCase().indexOf(query.toLowerCase());
    if (exactMatch != -1) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(style: styleNormal, children: [
          TextSpan(text: text.substring(0, exactMatch)),
          TextSpan(
            text: text.substring(exactMatch, exactMatch + query.length),
            style: const TextStyle(color: Color(0xFFEAB308), backgroundColor: Color(0x33EAB308)),
          ),
          TextSpan(text: text.substring(exactMatch + query.length)),
        ]),
      );
    }

    return Text(text, style: styleNormal, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
