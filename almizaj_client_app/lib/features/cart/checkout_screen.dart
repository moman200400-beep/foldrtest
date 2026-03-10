import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:almizaj_client_app/core/network/api_config.dart';
import 'package:almizaj_client_app/features/cart/cart_provider.dart';
import 'package:almizaj_client_app/features/auth/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';

class Neighborhood {
  final int id;
  final String name;

  Neighborhood({required this.id, required this.name});

  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      id: json['id'],
      name: json['name'],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final double totalAmount;
  final List<CartItem> cartItems;

  const CheckoutScreen({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String paymentMethod = 'cash';
  bool isSendingOrder = false;
  bool _orderSuccess = false;
  final _formKey = GlobalKey<FormState>();

  // Delivery Fee & Neighborhood state
  double? deliveryFee;
  bool isCalculatingFee = false;
  String feeError = '';
  bool freeDeliveryApplied = false;

  List<Neighborhood> neighborhoods = [];
  Neighborhood? selectedNeighborhood;

  double? lat;
  double? lng;
  bool isGettingLocation = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController neighborhoodSearchController =
      TextEditingController();
  final TextEditingController couponController = TextEditingController();
  bool isApplyingCoupon = false;

  @override
  void initState() {
    super.initState();
    _loadNeighborhoods();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false);
      if (user.name.isNotEmpty && user.name != 'زائر') {
        nameController.text = user.name;
      }
      if (user.phone.isNotEmpty && user.phone != 'guest') {
        phoneController.text = user.phone;
      }
    });
  }

  Future<void> _loadNeighborhoods() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/delivery/neighborhoods'));
      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        if (body['ok'] == true) {
          final list = (body['neighborhoods'] as List)
              .map((n) => Neighborhood.fromJson(n))
              .toList();
          setState(() {
            neighborhoods = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _calculateDelivery(int neighborhoodId) async {
    setState(() {
      isCalculatingFee = true;
      feeError = '';
      freeDeliveryApplied = false;
    });
    try {
      // نستخدم finalTotal (بعد خصم الكوبون) لحساب التوصيل المجاني بشكل صحيح
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final payload = <String, dynamic>{
        'neighborhood_id': neighborhoodId,
        'order_total': cartProvider.finalTotal
      };
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/delivery/calculate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true) {
          setState(() {
            deliveryFee = (data['price'] as num).toDouble();
            freeDeliveryApplied = data['free_delivery_applied'] == true;
            feeError = '';
          });
        } else {
          setState(() {
            deliveryFee = null;
            freeDeliveryApplied = false;
            feeError = data['error'] ?? 'المنطقة غير متوفرة للتوصيل حالياً';
          });
        }
      } else {
        setState(() {
          deliveryFee = null;
          freeDeliveryApplied = false;
          feeError = 'حدث خطأ أثناء تقييم التوصيل';
        });
      }
    } catch (e) {
      setState(() {
        deliveryFee = null;
        freeDeliveryApplied = false;
        feeError = 'فشل الاتصال بشبكة التوصيل';
      });
    } finally {
      if (mounted) setState(() => isCalculatingFee = false);
    }
  }

  Future<void> _applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => isApplyingCoupon = true);

    try {
      final payload = {
        'code': code,
        'cart_total': widget.totalAmount,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/cart/validate_coupon'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true) {
          final discount = (data['discount_amount'] as num).toDouble();
          if (mounted) {
            Provider.of<CartProvider>(context, listen: false)
                .setCouponData(code, discount);
            _showSnackBar(data['message'] ?? 'تم تطبيق الكوبون', Colors.green);
            couponController.clear();
          }
        } else {
          if (mounted) _showSnackBar(data['error'] ?? 'كوبون غير صالح', Colors.red, isFailure: true);
        }
      } else {
        if (mounted) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          _showSnackBar(data['error'] ?? 'خطأ في التحقق من الكوبون', Colors.red, isFailure: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('تعذر الاتصال بالخادم', Colors.red, isFailure: true);
    } finally {
      if (mounted) setState(() => isApplyingCoupon = false);
    }
  }

  void _removeCoupon() {
    Provider.of<CartProvider>(context, listen: false).removeCoupon();
  }

  Future<void> _getLocation() async {
    setState(() => isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('تم رفض صلاحية الموقع', Colors.red, isFailure: true);
          setState(() => isGettingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('صلاحية الموقع مرفوضة دائماً', Colors.red, isFailure: true);
        setState(() => isGettingLocation = false);
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition();
      
      String geoAddress = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [place.street, place.subLocality, place.locality, place.administrativeArea]
            .where((p) => p != null && p.isNotEmpty)
            .toList();
          if (parts.isNotEmpty) {
             geoAddress = parts.join(', ');
          }
        }
      } catch (e) {
        // Geocoding might fail, ignore silently
      }

      final googleMapsUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        
        String currentText = addressController.text.trim();
        if (currentText.isEmpty) {
          if (geoAddress.isNotEmpty) {
            addressController.text = '$geoAddress\n$googleMapsUrl';
          } else {
            addressController.text = googleMapsUrl;
          }
        } else if (!currentText.contains('maps.google.com')) {
          addressController.text = '$currentText\n$googleMapsUrl';
        }
      });
      _showSnackBar('تم تحديد الموقع بنجاح', Colors.green);
    } catch (e) {
      _showSnackBar('فشل في تحديد الموقع', Colors.red, isFailure: true);
    } finally {
      setState(() => isGettingLocation = false);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (selectedNeighborhood == null) {
      _showSnackBar('الرجاء اختيار حي التوصيل', Colors.red);
      return;
    }

    setState(() => isSendingOrder = true);

    List<Map<String, dynamic>> cartJson = widget.cartItems.map((item) {
      return {
        "id": item.id,
        "name": item.name,
        "price": item.price,
        "quantity": item.quantity,
      };
    }).toList();

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final orderData = {
      "uid": Provider.of<UserProvider>(context, listen: false).phone.isNotEmpty
          ? Provider.of<UserProvider>(context, listen: false).phone
          : "guest",
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
      "delivery_neighborhood": selectedNeighborhood!.name,
      "neighborhood_id": selectedNeighborhood!.id,
      "lat": lat,
      "lng": lng,
      "cart": cartJson,
      "total": cartProvider.finalTotal, // Backend recalculates total with DB product price to avoid tampering
      "coupon_code": cartProvider.appliedCouponCode,
      "location_link": lat != null && lng != null ? "https://maps.google.com/?q=$lat,$lng" : null,
      "payment_method": paymentMethod == 'cash'
          ? 'كاش/شبكة عند الاستلام'
          : (paymentMethod == 'apple' ? 'Apple Pay' : 'STC Pay'),
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/order'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(orderData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true && mounted) {
          setState(() {
            isSendingOrder = false;
            _orderSuccess = true;
          });
          if (widget.totalAmount >= 100) {
            final userProv = Provider.of<UserProvider>(context, listen: false);
            await userProv.grantWheelSpin();
          }
          await Future.delayed(const Duration(seconds: 3));
          if (!mounted) return;
          Provider.of<CartProvider>(context, listen: false).clear();
          Navigator.pop(context, true);
        } else {
          if (mounted) {
            _showSnackBar('فشل إتمام الطلب، يرجى المحاولة مرة أخرى.', Colors.red, isFailure: true);
            setState(() => isSendingOrder = false);
          }
        }
      } else {
        if (mounted) {
          _showSnackBar(
            'فشل إتمام الطلب، يرجى المحاولة مرة أخرى.',
            Colors.red,
            isFailure: true,
          );
          setState(() => isSendingOrder = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل إتمام الطلب، يرجى المحاولة مرة أخرى.', Colors.red, isFailure: true);
        setState(() => isSendingOrder = false);
      }
    }
  }

  void _showSnackBar(String msg, Color color, {bool isFailure = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isFailure) const Icon(Icons.error_outline, color: Colors.white, size: 24),
            if (isFailure) const SizedBox(width: 12),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Tajawal')),
            ),
          ],
        ),
        backgroundColor: isFailure ? const Color(0xFFE11D48) : color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
        elevation: 10,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    neighborhoodSearchController.dispose();
    couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A), // Dark Luxury Theme
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: const Text(
            'إتمام الدفع الآمن',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontFamily: 'Tajawal',
            ),
          ).animate().fade().slideY(begin: -0.2, end: 0),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: Stack(
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── بطاقة الإجمالي ──
                  Container(
                    padding: const EdgeInsets.all(20),
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الإجمالي المطلوب للدفع',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Consumer<CartProvider>(
                              builder: (context, cart, child) {
                                final currentDis = cart.discountAmount;
                                final dTotal = cart.finalTotal + (deliveryFee ?? 0.0);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (currentDis > 0)
                                      Text(
                                        'خصم الكوبون: ${currentDis.toStringAsFixed(2)} ر.س',
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    Text(
                                      '${dTotal.toStringAsFixed(2)} ر.س',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const FaIcon(
                          FontAwesomeIcons.shieldHalved,
                          color: Color(0xFF06B6D4),
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'معلومات التوصيل 🚚',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ).animate().fade().slideX(begin: 0.1, end: 0, delay: const Duration(milliseconds: 100)),
                  const SizedBox(height: 15),
                  _buildTextField(
                    nameController, 'الاسم الكامل', Icons.person_outline,
                    validator: (v) => v!.trim().isEmpty ? 'الرجاء إدخال اسمك الكامل' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    phoneController, 'رقم الجوال (05xxxxxxxx)', Icons.phone_outlined, 
                    isPhone: true,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v!.trim().isEmpty || !RegExp(r'^05\d{8}$').hasMatch(v.trim())) {
                        return 'رقم الجوال يجب أن يتكون من 10 أرقام ويبدأ بـ 05';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'موقع التوصيل 📍',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ).animate().fade().slideX(begin: 0.1, end: 0, delay: const Duration(milliseconds: 150)),
                  const SizedBox(height: 10),

                  // ── قائمة الأحياء مع البحث ──
                  GlassContainer(
                    borderRadius: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    child: DropdownMenu<Neighborhood>(
                      controller: neighborhoodSearchController,
                      width: MediaQuery.of(context).size.width - 40,
                      hintText: 'ابحث عن الحي أو اختر من القائمة...',
                      enableFilter: true,
                      requestFocusOnTap: true,
                      leadingIcon: Icon(Icons.location_city,
                          color: Colors.white.withValues(alpha: 0.7), size: 20),
                      textStyle: const TextStyle(
                          color: Colors.white, fontFamily: 'Tajawal'),
                      inputDecorationTheme: InputDecorationTheme(
                        border: InputBorder.none,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontFamily: 'Tajawal',
                            fontSize: 13),
                      ),
                      dropdownMenuEntries: neighborhoods.map((n) {
                        return DropdownMenuEntry<Neighborhood>(
                          value: n,
                          label: n.name,
                        );
                      }).toList(),
                      onSelected: (Neighborhood? n) {
                        setState(() {
                          selectedNeighborhood = n;
                          deliveryFee = null;
                        });
                        if (n != null) {
                          _calculateDelivery(n.id);
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _getLocation();
                    },
                    child: GlassContainer(
                      borderRadius: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isGettingLocation)
                            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)))
                          else
                             Icon(Icons.my_location, color: lat != null ? const Color(0xFF10B981) : const Color(0xFF06B6D4), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            lat != null ? 'تم التحديد بنجاح ✓' : 'تحديد موقعي تلقائياً',
                            style: TextStyle(
                              color: lat != null ? const Color(0xFF10B981) : const Color(0xFF06B6D4),
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0, delay: const Duration(milliseconds: 170)),
                  ),

                  if (isCalculatingFee)
                    const Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (feeError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(feeError,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),

                  // ── مؤشر التوصيل المجاني ──
                  if (deliveryFee != null && freeDeliveryApplied)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_shipping, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'تهانينا! التوصيل مجاني لهذا الطلب 🎉',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms)
                  else if (deliveryFee != null && deliveryFee! > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, color: Colors.white70, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'رسوم التوصيل',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${deliveryFee!.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms),

                  const SizedBox(height: 15),
                  _buildTextField(
                    addressController,
                    'عنوان التوصيل (الشارع، رقم المبنى، معلم مميز)...',
                    Icons.home_work_outlined,
                    isMultiline: true,
                    validator: (v) => v!.trim().isEmpty ? 'الرجاء كتابة العنوان التفصيلي' : null,
                  ),
                  const SizedBox(height: 30),

                  // ── كود الخصم ──
                  const Text(
                    'كود الخصم 🎟️',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ).animate().fade().slideY(begin: 0.1, end: 0, delay: const Duration(milliseconds: 180)),
                  const SizedBox(height: 10),
                  Consumer<CartProvider>(builder: (context, cart, child) {
                    final hasCoupon = cart.appliedCouponCode != null;
                    return GlassContainer(
                      borderRadius: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: couponController,
                              enabled: !hasCoupon && !isApplyingCoupon,
                              style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: hasCoupon ? cart.appliedCouponCode : 'أدخل الكود هنا...',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontFamily: 'Tajawal'),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.confirmation_number_outlined, color: Colors.white.withValues(alpha: 0.6), size: 20),
                              ),
                            ),
                          ),
                          if (hasCoupon)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () {
                                _removeCoupon();
                                couponController.clear();
                              },
                            )
                          else
                            ElevatedButton(
                              onPressed: isApplyingCoupon ? null : _applyCoupon,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06B6D4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              ),
                              child: isApplyingCoupon
                                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('تطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                            ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0, delay: const Duration(milliseconds: 190));
                  }),
                  const SizedBox(height: 30),

                  // ── طريقة الدفع ──
                  const Text(
                    'اختر طريقة الدفع 💳',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ).animate().fade().slideY(
                      begin: 0.1,
                      end: 0,
                      delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 15),
                  _buildPaymentOption(
                      'cash', '💵', 'الدفع عند الاستلام (كاش/شبكة)'),
                  _buildPaymentOption('apple', '🍏', 'Apple Pay'),
                  _buildPaymentOption('stc', '📱', 'STC Pay'),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSendingOrder ||
                              isCalculatingFee ||
                              (selectedNeighborhood != null &&
                                  deliveryFee == null &&
                                  feeError.isNotEmpty)
                          ? null
                          : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                      ),
                      child: isSendingOrder
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : Text(
                              'تأكيد الطلب والدفع',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // Success Overlay
            if (_orderSuccess)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 100)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds),
                        const SizedBox(height: 20),
                        const Text(
                          'تم تأكيد الطلب بنجاح! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ).animate().fade().slideY(begin: 0.2, end: 0, delay: 500.ms),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),
          ],
         ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPhone = false, bool isMultiline = false, String? Function(String?)? validator, List<TextInputFormatter>? formatters}) {
    return GlassContainer(
      borderRadius: 12,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: TextFormField(
        controller: controller,
        validator: validator,
        inputFormatters: formatters,
        style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
        keyboardType: isPhone
            ? TextInputType.phone
            : (isMultiline ? TextInputType.multiline : TextInputType.text),
        maxLines: isMultiline ? 3 : 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontFamily: 'Tajawal'),
          prefixIcon:
              Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: Colors.redAccent, fontFamily: 'Tajawal', height: 0.5),
          contentPadding: EdgeInsets.symmetric(
              vertical: isMultiline ? 15 : 18, horizontal: 15),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }

  Widget _buildPaymentOption(String id, String icon, String title) {
    final isSelected = paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => paymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEC4899).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFFEC4899)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 15),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Tajawal'))),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFFEC4899), size: 22),
          ],
        ),
      ),
    )
        .animate()
        .fade()
        .slideY(begin: 0.1, end: 0, delay: const Duration(milliseconds: 300));
  }
}
