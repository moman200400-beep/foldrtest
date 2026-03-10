import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:almizaj_client_app/features/cart/cart_provider.dart';
import 'package:almizaj_client_app/features/products/favorites_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String Function(String) getImageUrl;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.getImageUrl,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int quantity = 1;
  bool isFavorite = false;
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;

  bool _isAnimatingCart = false;

  // مؤقت العرض المحدود
  Timer? _timer;
  int _remainingSeconds = 3600; // ساعة واحدة

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.4)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_heartController);

    // تشغيل المؤقت فقط إذا كان هناك خصم
    if (productDiscount != null && productDiscount! > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _heartController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── استخراج البيانات ──
  String get productName => widget.product['name']?.toString() ?? 'منتج';
  String get productCategory {
    final c = widget.product['category'] ?? widget.product['cat'];
    if (c == null ||
        c.toString().toLowerCase() == 'null' ||
        c.toString().trim().isEmpty) {
      return 'مميز';
    }
    return c.toString();
  }

  String get productDescription {
    final d = widget.product['description'];
    if (d != null &&
        d.toString().toLowerCase() != 'null' &&
        d.toString().trim().isNotEmpty) {
      return d.toString();
    }
    return 'هذا المنتج من أفضل مبيعاتنا، يتميز بجودة عالية وتصميم عصري يناسب احتياجاتك.';
  }

  double get productPrice {
    final p = widget.product['price'];
    if (p == null) return 0.0;
    if (p is int) return p.toDouble();
    if (p is double) return p;
    return double.tryParse(p.toString()) ?? 0.0;
  }

  double? get productDiscount {
    final d = widget.product['discount_price'];
    if (d == null ||
        d.toString().toLowerCase() == 'null' ||
        d.toString().trim().isEmpty) {
      return null;
    }
    if (d is int) return d.toDouble();
    if (d is double) return d;
    return double.tryParse(d.toString());
  }

  int get productStock {
    final s = widget.product['stock'];
    if (s == null) return 0;
    if (s is int) {
      return s;
    }
    if (s is double) return s.toInt();
    return int.tryParse(s.toString()) ?? 0;
  }

  String get productImage => widget.product['img']?.toString() ?? '';

  int get discountPercent {
    if (productDiscount == null || productDiscount! <= 0) return 0;
    return (((productPrice - productDiscount!) / productPrice) * 100).round();
  }

  String get timerText {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleFavorite() {
    final favs = Provider.of<FavoritesProvider>(context, listen: false);
    favs.toggle(widget.product['id'].toString());
    _heartController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  void _increaseQuantity() {
    if (quantity < productStock) {
      setState(() => quantity++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('وصلت للحد الأقصى!'), backgroundColor: Colors.orange),
      );
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) setState(() => quantity--);
  }

  void _addToCart() async {
    setState(() => _isAnimatingCart = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    final hasDiscount = productDiscount != null && productDiscount! > 0;
    Provider.of<CartProvider>(context, listen: false).addItem(
      widget.product['id'].toString(),
      productName,
      hasDiscount ? productDiscount! : productPrice,
      widget.getImageUrl(productImage),
      productStock,
      quantity,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text('تم إضافة $productName (x$quantity) للسلة! 🛒',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = productDiscount != null && productDiscount! > 0;
    final currentPrice = hasDiscount ? productDiscount! : productPrice;
    final isOutOfStock = productStock <= 0;
    final isLowStock = productStock > 0 && productStock <= 5;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── صورة المنتج مع AppBar شفاف ──
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    backgroundColor: const Color(0xFF0D0D1A),
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    actions: [
                      // زر المفضلة
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Consumer<FavoritesProvider>(
                          builder: (context, favs, _) {
                            final isFav = favs
                                .isFavorite(widget.product['id'].toString());
                            return CircleAvatar(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              child: ScaleTransition(
                                scale: _heartAnimation,
                                child: IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFav
                                        ? Colors.red
                                        : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  onPressed: _toggleFavorite,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1E1E2E).withValues(alpha: 0.5),
                              const Color(0xFF0D0D1A),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 80, 20, 20),
                                child: InteractiveViewer(
                                  panEnabled: true,
                                  boundaryMargin: const EdgeInsets.all(20),
                                  minScale: 0.5,
                                  maxScale: 3,
                                  child: Hero(
                                    tag:
                                        'product_image_${widget.product['id']}',
                                    child: Image.network(
                                      widget.getImageUrl(productImage),
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.image_not_supported,
                                          size: 100,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // شارة الخصم
                            if (hasDiscount)
                              Positioned(
                                top: 90,
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$discountPercent% خصم',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // القسم
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(productCategory,
                                style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),

                          // الاسم
                          Text(productName,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 12),

                          // التقييم
                          Row(
                            children: [
                              ...List.generate(
                                  5,
                                  (i) => Icon(
                                      i < 4 ? Icons.star : Icons.star_half,
                                      color: const Color(0xFFF59E0B),
                                      size: 18)),
                              const SizedBox(width: 8),
                              const Text('4.5',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(width: 6),
                              const Text('(128 تقييم)',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // السعر
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${currentPrice.toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981)),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${productPrice.toStringAsFixed(2)} ر.س',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF94A3B8),
                                        decoration: TextDecoration.lineThrough),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),

                          // مؤقت العرض
                          if (hasDiscount)
                            GlassContainer(
                              borderRadius: 12,
                              backgroundColor:
                                  const Color(0xFFEF4444).withValues(alpha: 0.1),
                              border: Border.all(
                                  color:
                                      const Color(0xFFEF4444).withValues(alpha: 0.3)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        color: Color(0xFFEF4444), size: 18),
                                    const SizedBox(width: 8),
                                    const Text('ينتهي العرض خلال: ',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            fontFamily: 'Tajawal')),
                                    Text(timerText,
                                        style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16)),
                                  ],
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(
                                    duration: 2.seconds, color: Colors.white24),

                          const SizedBox(height: 14),

                          // مقياس التوفر البصري
                          if (!isOutOfStock) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('التوفر',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'Tajawal')),
                                Text(
                                  isLowStock
                                      ? 'تبقى $productStock قطع فقط! ⚡'
                                      : 'متوفر',
                                  style: TextStyle(
                                    color: isLowStock
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: isLowStock ? (productStock / 20.0) : 1.0,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLowStock
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ] else
                            const Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red, size: 18),
                                SizedBox(width: 6),
                                Text('نفد من المخزون',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'Tajawal')),
                              ],
                            ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Color(0xFF1E1E2E)),
                          ),

                          // الوصف
                          const Text('وصف المنتج',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 10),
                          Text(productDescription,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  height: 1.8)),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Color(0xFFE2E8F0)),
                          ),

                          // أيقونات الثقة
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _trustBadge(FontAwesomeIcons.shieldHalved,
                                  'ضمان جودة', const Color(0xFF10B981)),
                              _trustBadge(FontAwesomeIcons.truckFast,
                                  'توصيل سريع', const Color(0xFF3B82F6)),
                              _trustBadge(FontAwesomeIcons.rotateLeft,
                                  'استرجاع مرن', const Color(0xFFF59E0B)),
                              _trustBadge(FontAwesomeIcons.lock, 'دفع آمن',
                                  const Color(0xFF8B5CF6)),
                            ],
                          ),

                          // القسم: يُشترى معاً عادةً
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Color(0xFF1E1E2E)),
                          ),
                          const Text('يُشترى معاً عادةً',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Tajawal')),
                          const SizedBox(height: 15),
                          GlassContainer(
                            height: 100,
                            borderRadius: 15,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: productImage.isNotEmpty
                                        ? Image.network(
                                            widget.getImageUrl(productImage),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey))
                                        : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey),
                                  ),
                                ),
                                const Icon(Icons.add,
                                    color: Colors.white54, size: 20),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                        child: FaIcon(FontAwesomeIcons.gift,
                                            color: Colors.white54, size: 30)),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('حزمة التوفير ذكية',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                fontFamily: 'Tajawal')),
                                        const SizedBox(height: 5),
                                        ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            minimumSize:
                                                const Size(double.infinity, 30),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          child: const Text('إضافة الحزمة',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── شريط الشراء السفلي ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // الكمية
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: isOutOfStock ? null : _decreaseQuantity,
                          ),
                          Text('$quantity',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: isOutOfStock ? null : _increaseQuantity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // زر الإضافة للسلة
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isOutOfStock ? null : _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.cartShopping,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                isOutOfStock
                                    ? 'نفد المخزون'
                                    : 'أضف للسلة  •  ${(currentPrice * quantity).toStringAsFixed(2)} ر.س',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(target: _isAnimatingCart ? 1 : 0)
                          .scaleXY(
                              end: 1.1, duration: 150.ms, curve: Curves.easeOut)
                          .then()
                          .scaleXY(
                              end: 1.0,
                              duration: 150.ms,
                              curve: Curves.bounceOut)
                          .moveY(end: -50, duration: 300.ms, delay: 100.ms)
                          .fadeOut(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
