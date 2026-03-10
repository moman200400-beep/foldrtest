import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:almizaj_client_app/core/network/api_config.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  final int maxStock;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    required this.maxStock,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  
  bool freeDeliveryActive = false;
  double freeDeliveryThreshold = 300.0;

  String? appliedCouponCode;
  double discountAmount = 0.0;

  Map<String, CartItem> get items => _items;

  void setFreeDeliverySettings(bool active, double threshold) {
    freeDeliveryActive = active;
    freeDeliveryThreshold = threshold;
    notifyListeners();
  }

  /// جلب إعدادات التوصيل المجاني من السيرفر مباشرة
  Future<void> fetchFreeDeliverySettings() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/settings/free_delivery'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true) {
          freeDeliveryActive = data['free_delivery_active'] == true;
          freeDeliveryThreshold =
              (data['free_delivery_threshold'] ?? 300.0).toDouble();
          notifyListeners();
        }
      }
    } catch (e) {
      // في حالة فشل الاتصال نبقي على القيم الحالية
    }
  }

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  double get finalTotal {
    double finalAmt = totalAmount - discountAmount;
    return finalAmt < 0 ? 0.0 : finalAmt;
  }

  void setCouponData(String code, double discount) {
    appliedCouponCode = code;
    discountAmount = discount;
    notifyListeners();
  }

  void removeCoupon() {
    appliedCouponCode = null;
    discountAmount = 0.0;
    notifyListeners();
  }

  void addItem(
    String productId,
    String name,
    double price,
    String imageUrl,
    int maxStock,
    int qty,
  ) {
    if (_items.containsKey(productId)) {
      // إذا كان موجوداً، نزيد الكمية بشرط ألا تتجاوز المخزون
      final newQty = _items[productId]!.quantity + qty;
      if (newQty <= maxStock) {
        _items[productId]!.quantity = newQty;
      } else {
        // يمكن إظهار رسالة للمستخدم
      }
    } else {
      _items[productId] = CartItem(
        id: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: qty,
        maxStock: maxStock,
      );
    }
    notifyListeners();
  }

  // زيادة كمية منتج من داخل السلة
  void incrementQuantity(String productId) {
    if (_items.containsKey(productId) &&
        _items[productId]!.quantity < _items[productId]!.maxStock) {
      _items[productId]!.quantity++;
      notifyListeners();
    }
  }

  // إنقاص كمية منتج من السلة
  void decrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(
          productId,
        ); // إذا كانت الكمية 1 ونقصناها، نحذف المنتج بحركة سلسة
      }
      notifyListeners();
    }
  }

  // حذف منتج بالكامل من السلة
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // تفريغ السلة (بعد الدفع)
  void clear() {
    _items.clear();
    appliedCouponCode = null;
    discountAmount = 0.0;
    notifyListeners();
  }
}
