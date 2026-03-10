import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:almizaj_client_app/core/network/api_config.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';

import 'package:almizaj_client_app/features/cart/cart_provider.dart';
import 'package:almizaj_client_app/features/auth/user_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> myOrders = [];
  String currentFilter = 'all';
  Set<String> expandedOrders = {}; // Order IDs for tracking expansion state
  final Map<String, int> _orderRatings = {}; // Stores rating for each order

  @override
  void initState() {
    super.initState();
    _fetchMyOrders();
  }

  Future<void> _fetchMyOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/my_orders?uid=${Provider.of<UserProvider>(context, listen: false).phone}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok']) {
          if (mounted) {
            setState(() {
              myOrders = data['orders'] ?? [];
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              errorMessage = 'حدث خطأ في جلب الطلبات.';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'خطأ اتصال: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'لا يمكن الوصول للسيرفر. تأكد من تشغيله.';
          isLoading = false;
        });
      }
    }
  }

  List<dynamic> get filteredOrders {
    switch (currentFilter) {
      case 'completed':
        return myOrders.where((o) => o['status'] == 'completed').toList();
      case 'pending':
        return myOrders
            .where(
                (o) => o['status'] == 'pending' || o['status'] == 'processing')
            .toList();
      case 'cancelled':
        return myOrders
            .where(
                (o) => o['status'] == 'cancelled' || o['status'] == 'refunded')
            .toList();
      default:
        return myOrders;
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'label': 'قيد المعالجة',
          'icon': Icons.timer_outlined,
          'bg': const Color(0xFFFFF7ED),
          'color': const Color(0xFFF59E0B),
        };
      case 'processing':
        return {
          'label': 'جاري التحضير',
          'icon': Icons.sync,
          'bg': const Color(0xFFEFF6FF),
          'color': const Color(0xFF3B82F6),
        };
      case 'completed':
        return {
          'label': 'مكتمل ✓',
          'icon': Icons.check_circle_outline,
          'bg': const Color(0xFFECFDF5),
          'color': const Color(0xFF10B981),
        };
      case 'cancelled':
      case 'refunded':
        return {
          'label': 'ملغي',
          'icon': Icons.cancel_outlined,
          'bg': const Color(0xFFFEF2F2),
          'color': const Color(0xFFEF4444),
        };
      default:
        return {
          'label': 'غير معروف',
          'icon': Icons.help_outline,
          'bg': Colors.grey.shade100,
          'color': Colors.grey,
        };
    }
  }

  List<Map<String, dynamic>> _getTimeline(String status) {
    final steps = [
      {'label': 'تم الاستلام', 'icon': Icons.receipt_outlined},
      {'label': 'جاري التحضير', 'icon': Icons.sync},
      {'label': 'في الطريق', 'icon': Icons.local_shipping_outlined},
      {'label': 'تم التسليم', 'icon': Icons.check_circle_outline},
    ];

    int activeIndex = 0;
    if (status == 'processing') activeIndex = 1;
    if (status == 'shipping') activeIndex = 2;
    if (status == 'completed') activeIndex = 3;

    return steps.asMap().entries.map((e) {
      return {
        ...e.value,
        'done': e.key <= activeIndex,
        'active': e.key == activeIndex,
      };
    }).toList();
  }

  List<dynamic> _parseCartItems(dynamic raw) {
    if (raw == null) return [];
    try {
      if (raw is String) return json.decode(raw);
      if (raw is List) return raw;
    } catch (_) {}
    return [];
  }

  void _reorder(dynamic order) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = _parseCartItems(order['cart_items']);
    for (final item in items) {
      cart.addItem(
        item['id'].toString(),
        item['name'].toString(),
        double.tryParse(item['price'].toString()) ?? 0,
        '',
        99,
        int.tryParse(item['quantity'].toString()) ?? 1,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تمت إضافة المنتجات للسلة!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'طلباتي 📦',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              fontSize: 20,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF8B5CF6)),
              onPressed: _fetchMyOrders,
            ),
          ],
        ),
        body: Column(
          children: [
            // ── تبويبات الفلترة ──
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterTab('الكل', 'all', myOrders.length),
                    _filterTab(
                        'قيد المعالجة',
                        'pending',
                        myOrders
                            .where((o) =>
                                o['status'] == 'pending' ||
                                o['status'] == 'processing')
                            .length),
                    _filterTab(
                        'مكتملة',
                        'completed',
                        myOrders
                            .where((o) => o['status'] == 'completed')
                            .length),
                    _filterTab(
                        'ملغاة',
                        'cancelled',
                        myOrders
                            .where((o) =>
                                o['status'] == 'cancelled' ||
                                o['status'] == 'refunded')
                            .length),
                  ],
                ),
              ),
            ),

            // ── المحتوى ──
            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    )
                  : errorMessage.isNotEmpty
                      ? _buildError()
                      : filteredOrders.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _fetchMyOrders,
                              color: const Color(0xFF8B5CF6),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredOrders.length,
                                itemBuilder: (ctx, i) =>
                                    _buildOrderCard(filteredOrders[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterTab(String label, String value, int count) {
    final isActive = currentFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => currentFilter = value);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          borderRadius: 20,
          backgroundColor: isActive
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
              color: isActive
                  ? const Color(0xFF8B5CF6)
                  : Colors.white.withValues(alpha: 0.1)),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Tajawal',
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate(target: isActive ? 1 : 0).scaleXY(end: 1.05, duration: 200.ms),
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final status = _getStatusInfo(o['status'] ?? '');
    final orderId = o['id'].toString(); // Changed to String
    final isExpanded = expandedOrders.contains(orderId);
    final items = _parseCartItems(o['cart_items']);
    final timeline = _getTimeline(o['status'] ?? '');

    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(
          borderRadius: 20,
          backgroundColor: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          child: Column(
            children: [
              // ── رأس البطاقة ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'طلب #',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            Text(
                              orderId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: '#$orderId'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ رقم الطلب'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Icon(Icons.copy,
                                  size: 14, color: Colors.white54),
                            ),
                          ],
                        ),
                        _buildStatusBadge(status)
                            .animate()
                            .fade()
                            .scaleXY(begin: 0.8, end: 1.0, duration: 400.ms),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 13, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          o['created_at']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Timeline ──
              if (o['status'] != 'cancelled' && o['status'] != 'refunded')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTimeline(timeline),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Color(0xFFE2E8F0)),
              ),

              // ── المنتجات المطوية ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.bagShopping,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items.isEmpty
                              ? 'لا توجد تفاصيل'
                              : items
                                  .map(
                                      (i) => '${i['name']} (x${i['quantity']})')
                                  .join('، '),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF8B5CF6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['name']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontFamily: 'Tajawal'),
                                    ),
                                  ],
                                ),
                                Text(
                                  'x${item['quantity']}  •  ${item['price']} ر.س',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          )),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),

                // ── Rating Section ──
                if (o['status'] == 'delivered' || o['status'] == 'completed')
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _buildRatingSection(o),
                    ),
                  ),

                // ── طريقة الدفع ──
              if (o['payment_method'] != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.payment,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        o['payment_method'].toString(),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Color(0xFFE2E8F0)),
              ),

              // ── أسفل البطاقة ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الإجمالي',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                        Text(
                          '${o['total_amount']} ر.س',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // زر تفاصيل
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                expandedOrders.remove(orderId);
                              } else {
                                expandedOrders.add(orderId);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  isExpanded ? 'إخفاء' : 'التفاصيل',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // زر إعادة الشراء
                        GestureDetector(
                          onTap: () => _reorder(o),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.refresh,
                                    size: 14, color: Color(0xFF8B5CF6)),
                                SizedBox(width: 4),
                                Text(
                                  'إعادة الشراء',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildStatusBadge(Map<String, dynamic> status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status['bg'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (status['color'] as Color).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status['icon'] as IconData,
              size: 13, color: status['color'] as Color),
          const SizedBox(width: 5),
          Text(
            status['label'],
            style: TextStyle(
              color: status['color'] as Color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Map<String, dynamic>> steps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isDone = step['done'] as bool;
          final isActive = step['active'] as bool;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF8B5CF6)
                              : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withValues(alpha: 0.2),
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2)
                                ]
                              : [],
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 14,
                          color: isDone ? Colors.white : Colors.white54,
                        ),
                      )
                          .animate(target: isActive ? 1 : 0)
                          .scaleXY(end: 1.1, duration: 400.ms)
                          .shimmer(duration: 2.seconds, color: Colors.white24),
                      const SizedBox(height: 4),
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Tajawal',
                          color:
                              isDone ? const Color(0xFF8B5CF6) : Colors.white54,
                          fontWeight:
                              isDone ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: isDone
                          ? const Color(0xFF8B5CF6)
                          : Colors.white.withValues(alpha: 0.1),
                    )
                        .animate(target: isDone ? 1 : 0)
                        .tint(color: const Color(0xFF8B5CF6), duration: 300.ms),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingSection(Map<String, dynamic> o) {
    final orderId = o['id'].toString();
    final currentRating = _orderRatings[orderId] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تقييم الطلب', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = starIndex <= currentRating;
            return GestureDetector(
              onTap: () {
                setState(() => _orderRatings[orderId] = starIndex);
                HapticFeedback.selectionClick();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
                  size: 32,
                  shadows: isSelected ? [
                    Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.6), blurRadius: 15)
                  ] : [],
                ).animate(target: isSelected ? 1 : 0).scaleXY(end: 1.2, duration: 200.ms).then().scaleXY(end: 1.0, duration: 200.ms),
              ),
            );
          }),
        ),
      ],
    ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.boxOpen,
              size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          const Text(
            'لا توجد طلبات هنا!',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ تسوقك الآن وستظهر طلباتك هنا',
            style: TextStyle(
                color: Colors.white54, fontSize: 13, fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.circleExclamation,
              size: 40, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(errorMessage,
              style: const TextStyle(
                  color: Colors.redAccent, fontFamily: 'Tajawal'),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchMyOrders,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('إعادة المحاولة',
                style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
}
