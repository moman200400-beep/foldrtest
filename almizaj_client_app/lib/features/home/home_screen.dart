import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:almizaj_client_app/features/cart/cart_provider.dart';
import 'package:almizaj_client_app/shared/widgets/product_card.dart';
import 'package:almizaj_client_app/shared/widgets/loading_skeleton.dart';
import 'package:almizaj_client_app/features/home/search_screen.dart';
import 'package:almizaj_client_app/core/network/api_config.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';
import 'package:almizaj_client_app/features/mix/screens/mix_intro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String errorMessage = '';
  String storeName = "المزاج الأول";
  String storeLogo = "";
  bool isStoreOpen = true;
  List<String> categories = ["الكل"];
  String selectedCategory = "الكل";
  List<dynamic> allProducts = [];
  List<dynamic> banners = [];
  List<dynamic> ads = [];

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchHomeData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String getImageUrl(String path) {
    if (path.isEmpty) {
      return 'https://via.placeholder.com/400x200?text=No+Image';
    }
    String cleanPath = path.replaceAll('\\', '/');
    if (cleanPath.startsWith('http')) return cleanPath;
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    return '${ApiConfig.baseUrl}$cleanPath';
  }

  Future<void> _fetchHomeData() async {
    try {
      final response =
          await http.get(Uri.parse('${ApiConfig.baseUrl}/api/home'));
      final adsResponse =
          await http.get(Uri.parse('${ApiConfig.baseUrl}/api/ads'));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true && mounted) {
          setState(() {
            isStoreOpen = data['store_open'] ?? true;
            storeName = data['store_name'] ?? "المزاج الأول";
            storeLogo = data['store_logo'] ?? "";
            categories = data['categories'] is List
                ? List<String>.from(data['categories'])
                : ["الكل", "شيش", "معسل", "فحم"];
            banners = data['banners'] ?? [];
            allProducts = data['products'] ?? [];
          });
          Provider.of<CartProvider>(context, listen: false)
              .setFreeDeliverySettings(data['free_delivery_active'] == true,
                  (data['free_delivery_threshold'] ?? 300.0).toDouble());
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'خطأ: ${response.statusCode}';
          });
        }
      }

      // جلب الإعلانات
      if (adsResponse.statusCode == 200) {
        final adsData = json.decode(utf8.decode(adsResponse.bodyBytes));
        if (adsData['ok'] == true && mounted) {
          setState(() {
            ads = adsData['ads'] ?? [];
          });
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'تعذّر الاتصال بالسيرفر';
          isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'صباح الخير والنشاط ☀️';
    } else if (hour < 17) {
      return 'طاب مساؤك ☕';
    } else {
      return 'مساء الخير والروقان 🌙';
    }
  }

  List<dynamic> get filteredProducts {
    if (selectedCategory == "الكل") return allProducts;
    return allProducts.where((p) => p['cat'] == selectedCategory).toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    if (product['stock'] <= 0) {
      _showSnack(
          'الكمية نفدت!', const Color(0xFFEF4444), Icons.warning_amber_rounded);
      return;
    }
    double price = double.tryParse(product['price'].toString()) ?? 0.0;
    double? discount = product['discount_price'] != null
        ? double.tryParse(product['discount_price'].toString())
        : null;
    double finalPrice = (discount != null && discount > 0) ? discount : price;

    Provider.of<CartProvider>(context, listen: false).addItem(
      product['id'].toString(),
      product['name'].toString(),
      finalPrice,
      getImageUrl(product['img']?.toString() ?? ''),
      int.tryParse(product['stock'].toString()) ?? 0,
      1,
    );
    HapticFeedback.lightImpact();
    _showSnack('تم إضافة "${product['name']}" للسلة', const Color(0xFF10B981),
        Icons.check_circle_rounded);
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Tajawal'))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const HomeSkeletonLoader();
    if (errorMessage.isNotEmpty) return _buildError();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: CustomScrollView(
              slivers: [
                // ── Dynamic Header with Greeting ──
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  expandedHeight: 230,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Subtle animated background blur
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 50),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getGreeting(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        storeName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Profile / Logo Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEC4899)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ],
                                      image: storeLogo.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                  getImageUrl(storeLogo)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: storeLogo.isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white, size: 24)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Search bar (Glassmorphism)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SearchScreen())),
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      const FaIcon(
                                          FontAwesomeIcons.magnifyingGlass,
                                          color: Colors.white70,
                                          size: 18),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'ابحث عن مزاجك المفضل...',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withValues(alpha: 0.7),
                                            fontSize: 14,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEC4899)
                                              .withValues(alpha: 0.2),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                          ),
                                        ),
                                        child: const FaIcon(
                                            FontAwesomeIcons.microphone,
                                            color: Color(0xFFEC4899),
                                            size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Body ──
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),

                    // تنبيه المتجر مغلق
                    if (!isStoreOpen)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline, color: Color(0xFFEF4444)),
                          SizedBox(width: 10),
                          Expanded(
                              child: Text('المتجر مغلق حالياً',
                                  style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal'))),
                        ]),
                      ),

                    // ── البنرات ──
                    if (banners.isNotEmpty) ...[
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 140,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 800),
                          viewportFraction: 0.88,
                        ),
                        items: banners
                            .map((b) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image:
                                          NetworkImage(getImageUrl(b['img'])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.2)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── الإعلانات ──
                    if (ads.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Text('📢 الإعلانات والعروض',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Tajawal',
                            )),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: ads.length,
                          itemBuilder: (context, index) {
                            final ad = ads[index];
                            return GestureDetector(
                              onTap: () {
                                if (ad['link'] != null &&
                                    ad['link'].toString().isNotEmpty &&
                                    ad['link'] != '#') {
                                  // يمكن إضافة فتح الرابط هنا إذا لزم الأمر
                                }
                              },
                              child: Container(
                                width: 280,
                                margin: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEC4899)
                                          .withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image:
                                        NetworkImage(getImageUrl(ad['image'])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        (() {
                                          String hex =
                                              ad['bg_color']?.toString() ??
                                                  '#1E293B';
                                          hex = hex
                                              .replaceAll('#', '')
                                              .toUpperCase();
                                          if (hex.length == 6) hex = 'FF$hex';
                                          if (hex.length == 3) {
                                            hex =
                                                'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
                                          }
                                          try {
                                            return Color(
                                                int.parse(hex, radix: 16));
                                          } catch (_) {
                                            return Colors.black;
                                          }
                                        })()
                                            .withValues(
                                                alpha:
                                                    0.95), // اللون المخصص للإعلان من الإدارة
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ad['title'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Tajawal',
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (ad['description'] != null &&
                                            ad['description']
                                                .toString()
                                                .trim()
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              ad['description'],
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                  fontSize: 12,
                                                  fontFamily: 'Tajawal',
                                                  height: 1.2),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── مزاجك اليوم (Hyper-Personalization) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MixIntroScreen()));
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF8B5CF6),
                                  Color(0xFFA78BFA),
                                ],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.wandMagicSparkles,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      '✨ صمّم مزاجك الخاص',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ابدأ الآن',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).animate().fade().slideY(begin: 0.1, end: 0),
                    ),
                    const SizedBox(height: 25),

                    // ── الأقسام ──
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (_, i) {
                          final isActive = selectedCategory == categories[i];
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => selectedCategory = categories[i]);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(left: 10),
                              child: GlassContainer(
                                backgroundColor: isActive
                                    ? const Color(0xFFEC4899).withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: 20,
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFFEC4899)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: isActive ? 1.5 : 1,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  child: Center(
                                    child: Text(
                                      categories[i],
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.7),
                                        fontWeight: isActive
                                            ? FontWeight.w900
                                            : FontWeight.w500,
                                        fontSize: 14,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── عنوان المنتجات ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🔥 تشكيلة اليوم',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Tajawal',
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Text('عرض الكل',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  fontFamily: 'Tajawal',
                                )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── المنتجات ──
                    if (filteredProducts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(50),
                          child: Text('لا توجد منتجات في هذا القسم',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontFamily: 'Tajawal')),
                        ),
                      )
                    else
                      GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (_, i) => ProductCard(
                          product: filteredProducts[i],
                          getImageUrl: getImageUrl,
                          onAddToCart: () => _addToCart(filteredProducts[i]),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // ── Trust Badges ──
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _trustBadge(FontAwesomeIcons.shieldHalved, 'دفع آمن',
                              const Color(0xFF10B981)),
                          _dividerLine(),
                          _trustBadge(FontAwesomeIcons.bolt, 'تسليم فوري',
                              const Color(0xFFF59E0B)),
                          _dividerLine(),
                          _trustBadge(FontAwesomeIcons.lock, 'بيانات مشفرة',
                              const Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ],
            ),
          ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: FaIcon(icon, color: color, size: 18)),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal')),
      ],
    );
  }

  Widget _dividerLine() => Container(
        width: 1,
        height: 40,
        color: Colors.black.withValues(alpha: 0.08),
      );

  Widget _buildError() => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const FaIcon(FontAwesomeIcons.circleExclamation,
              size: 50, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF666666), fontFamily: 'Tajawal')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {
              isLoading = true;
              errorMessage = '';
              _fetchHomeData();
            }),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white),
            child: const Text('إعادة المحاولة',
                style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ])),
      );
}
