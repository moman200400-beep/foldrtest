import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:almizaj_client_app/features/cart/cart_provider.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';
import 'package:almizaj_client_app/features/cart/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // جلب إعدادات التوصيل المجاني من السيرفر عند فتح السلة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false)
          .fetchFreeDeliverySettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final total = cart.totalAmount;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFF0D0D1A), // Dark Luxury Theme
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'سلة المشتريات 🛍️',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                    ),
                  ).animate().fade().slideY(begin: -0.2, end: 0),
                  const SizedBox(width: 8),
                  if (cart.itemCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate(delay: 200.ms).scale(curve: Curves.easeOutBack),
                ],
              ),
              actions: [
                if (cart.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF1E293B),
                            title: const Text('تفريغ السلة',
                                style: TextStyle(color: Colors.white)),
                            content: const Text('هل تريد إزالة جميع المنتجات؟',
                                style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('إلغاء',
                                    style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () {
                                  cart.clear();
                                  Navigator.pop(ctx);
                                },
                                child: const Text('تفريغ',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: Colors.redAccent, size: 24),
                    ).animate().fade(),
                  ),
              ],
            ),
            body: Stack(
              children: [
                // Animated Blurs in Background
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEC4899).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                      begin: 0,
                      end: 20,
                      duration: const Duration(seconds: 4),
                      curve: Curves.easeInOut),
                ),
                Positioned(
                  bottom: -100,
                  left: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFA855F7).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(
                      begin: 0,
                      end: 20,
                      duration: const Duration(seconds: 5),
                      curve: Curves.easeInOut),
                ),

                cart.items.isEmpty
                    ? _buildEmptyCart(context)
                    : Positioned.fill(
                        child: Column(
                          children: [
                            // ── شريط التقدم ──
                            _buildProgressBar(),
                            
                            // ── شريط الشحن المجاني ──
                      if (cart.freeDeliveryActive)
                        _buildFreeShippingBar(total, cart.freeDeliveryActive, cart.freeDeliveryThreshold),

                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // ── المنتجات ──
                                  ...cart.items.entries.map((entry) {
                                    final productId = entry.key;
                                    final item = entry.value;
                                    return _buildCartItem(
                                        context, cart, productId, item);
                                  }),

                                  const SizedBox(height: 10),

                                  // ── ملخص السعر ──
                                  _buildPriceSummary(total, cart),

                                  const SizedBox(height: 120),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                // ── زر الدفع يطفو فوق المحتوى ──
                if (cart.items.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildCheckoutButton(context, cart, total),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: GlassContainer(
        borderRadius: 30,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.basketShopping,
                size: 80,
                color: Colors.white.withValues(alpha: 0.3),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: -15,
                  duration: 2.seconds,
                  curve: Curves.easeInOut),
              const SizedBox(height: 25),
              const Text(
                'سلتك فارغة حالياً!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              )
                  .animate(delay: const Duration(milliseconds: 200))
                  .fade()
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 10),
              Text(
                'اكتشف منتجاتنا وأضف ما يعجبك',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                ),
              ).animate(delay: const Duration(milliseconds: 400)).fade(),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shopping_bag_outlined),
                      SizedBox(width: 8),
                      Text('تسوق الآن',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal')),
                    ],
                  ),
                ),
              )
                  .animate(delay: const Duration(milliseconds: 600))
                  .scale(curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
      child: Row(
        children: [
          _buildStep('السلة', true, true),
          _buildLine(false),
          _buildStep('الدفع', false, false),
          _buildLine(false),
          _buildStep('تأكيد', false, false),
        ],
      ),
    );
  }

  Widget _buildFreeShippingBar(double total, bool isActive, double target) {
    if (!isActive) return const SizedBox.shrink();
    final double remaining = target - total;
    final double progress = (total / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remaining > 0 
                      ? 'أضف ${remaining.toStringAsFixed(1)} ر.س واحصل على شحن مجاني! 🚚'
                      : 'تهانينا! لقد حصلت على شحن مجاني 🎉',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
        ],
      ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms),
    );
  }

  Widget _buildStep(String label, bool active, bool done) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                  )
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color:
                  active ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            shape: BoxShape.circle,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    ).animate().fade().scale(delay: active ? 100.ms : 0.ms);
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        height: 2,
        decoration: BoxDecoration(
          color:
              active ? const Color(0xFFEC4899) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
      ).animate().fade().scaleX(alignment: Alignment.centerRight),
    );
  }

  Widget _buildCartItem(BuildContext context, CartProvider cart,
      String productId, CartItem item) {
    final isLowStock = item.maxStock > 0 && item.maxStock <= 3;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const FaIcon(FontAwesomeIcons.trashCan,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        HapticFeedback.heavyImpact();
        cart.removeItem(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إزالة "${item.name}" من السلة',
                style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: GlassContainer(
        borderRadius: 20,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // ── صورة المنتج ──
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: item.imageUrl == 'mix'
                          ? const Center(child: Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 40))
                          : Image.network(
                              item.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── معلومات المنتج ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${item.price.toStringAsFixed(2)} ر.س',
                          style: const TextStyle(
                            color: Color(0xFFEC4899),
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── التحكم بالكمية ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _qtyButton(
                          icon: Icons.add,
                          onTap: () {
                            if (item.quantity < item.maxStock) {
                              cart.incrementQuantity(productId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('وصلت للحد الأقصى المتاح',
                                      style: TextStyle(fontFamily: 'Tajawal')),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              );
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _qtyButton(
                          icon: Icons.remove,
                          onTap: () => cart.decrementQuantity(productId),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── تنبيه المخزون المنخفض ──
            if (isLowStock)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'تبقى ${item.maxStock} قطع فقط!',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 13,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(
                  begin: 0.2,
                  end: 0,
                  duration: const Duration(milliseconds: 300)),
          ],
        ),
      ).animate(delay: const Duration(milliseconds: 200)).fade().slideX(
          begin: 0.1, end: 0, duration: const Duration(milliseconds: 400)),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }


  Widget _buildPriceSummary(double total, CartProvider cart) {
    return GlassContainer(
      borderRadius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _summaryRow('الضريبة (15%)', 'مشمولة', Colors.white.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white.withValues(alpha: 0.1)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع الكلي',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(
                    color: Color(0xFF10B981), // Emerald green for final amount
                    fontSize: 20,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(delay: 800.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Tajawal',
                fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildCheckoutButton(
      BuildContext context, CartProvider cart, double finalTotal) {
    return GlassContainer(
      borderRadius: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      totalAmount: finalTotal,
                      cartItems: cart.items.values.toList(),
                    ),
                  ),
                ).then((orderSuccess) {
                  if (orderSuccess == true) {
                    cart.clear();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.lock,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'متابعة للدفع الآمن  •  ${finalTotal.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(
        begin: 1.0, end: 0, curve: Curves.easeOutCubic, duration: 500.ms);
  }
}
