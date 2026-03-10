import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:almizaj_client_app/core/network/api_config.dart';
class UserProvider with ChangeNotifier {
  String _name = 'زائر';
  String _phone = 'guest';
  String _email = '';
  String _uid = 'guest';
  bool _isLoggedIn = false;

  // إعدادات المتجر الديناميكية
  String _storeName = 'المزاج الأول';
  String _storeLogo = '';

  // حالة عجلة الحظ
  bool _hasSpunWheel = false;
  double _wheelDiscount = 0.0; // 0.05 = 5%
  bool _canSpinWheel = false; // تُفعَّل عند إتمام طلب بـ 100 ر.س فأكثر

  // Getters
  String get name => _name;
  String get phone => _phone;
  String get email => _email;
  String get uid => _uid;
  bool get isLoggedIn => _isLoggedIn;
  String get storeName => _storeName;
  String get storeLogo => _storeLogo;
  bool get hasSpunWheel => _hasSpunWheel;
  double get wheelDiscount => _wheelDiscount;
  bool get canSpinWheel => _canSpinWheel;

  Future<void> updateName(String newName) async {
    _name = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
    notifyListeners();
  }

  Future<void> updatePhone(String newPhone) async {
    _phone = newPhone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhone', newPhone);
    notifyListeners();
  }

  Future<void> updateEmail(String newEmail) async {
    _email = newEmail;
    notifyListeners();
  }

  // 1. دالة تهيئة الـ Provider (تُستدعى عند فتح التطبيق لتقرأ الذاكرة)
  Future<void> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (_isLoggedIn) {
      _name = prefs.getString('userName') ?? 'عميل';
      _phone = prefs.getString('userPhone') ?? '05xxxxxxxxx';
      _uid = prefs.getString('userUid') ?? 'user123';
    }
    // تحميل حالة العجلة
    _hasSpunWheel = prefs.getBool('hasSpunWheel') ?? false;
    _wheelDiscount = prefs.getDouble('wheelDiscount') ?? 0.0;
    _canSpinWheel = prefs.getBool('canSpinWheel') ?? false;
    notifyListeners();
  }

  // 2. دالة تسجيل الدخول (تحفظ في المتغيرات وفي الذاكرة)
  Future<void> login(
      {required String name,
      required String phone,
      String email = '',
      String uid = ''}) async {
    _name = name;
    _phone = phone;
    _email = email;
    _uid = uid;

    // إذا لم يكن زائراً، احفظه كمسجل دخول
    _isLoggedIn = phone != 'guest';

    if (_isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', name);
      await prefs.setString('userPhone', phone);
      await prefs.setString('userUid', uid);
    }

    notifyListeners();
  }

  // 3. دالة تسجيل الخروج (تمسح الذاكرة)
  Future<void> logout() async {
    _name = 'زائر';
    _phone = 'guest';
    _email = '';
    _uid = 'guest';
    _isLoggedIn = false;
    _hasSpunWheel = false;
    _wheelDiscount = 0.0;
    _canSpinWheel = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // مسح الذاكرة بالكامل

    notifyListeners();
  }

  // 4. دالة جلب إعدادات المتجر من السيرفر (خاصة الشعار)
  Future<void> fetchStoreSettings() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/home'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true) {
          _storeName = data['store_name'] ?? 'المزاج الأول';
          _storeLogo = data['store_logo'] ?? '';
          debugPrint('✅ تم جلب الشعار: $_storeLogo');
          notifyListeners(); // تأكد من تحديث الواجهة
        }
      }
    } catch (e) {
      debugPrint('❌ فشل جلب إعدادات المتجر: $e');
    }
  }

  // دالة تُستدعى بعد إتمام طلب بـ 100 ر.س فأكثر
  Future<void> grantWheelSpin() async {
    if (_hasSpunWheel) return; // لا تمنح فرصة ثانية إذا دار اليوم
    _canSpinWheel = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('canSpinWheel', true);
    notifyListeners();
  }

  // دالة لتحديث حالة العجلة بعد الدوران
  Future<void> setWheelSpun(double discount) async {
    _hasSpunWheel = true;
    _canSpinWheel = false; // استُهلكت الفرصة
    _wheelDiscount = discount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSpunWheel', true);
    await prefs.setBool('canSpinWheel', false);
    await prefs.setDouble('wheelDiscount', discount);
    notifyListeners();
  }

  // دالة لمسح حالة العجلة بعد استخدام الخصم
  Future<void> clearWheelState() async {
    _hasSpunWheel = false;
    _wheelDiscount = 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSpunWheel', false);
    await prefs.setBool('canSpinWheel', false);
    await prefs.setDouble('wheelDiscount', 0.0);
    notifyListeners();
  }

  // دالة مساعدة لبناء رابط الصورة الكامل (مشابهة لما في home_screen)
  String getFullImageUrl(String path) {
    if (path.isEmpty) return '';
    String cleanPath = path.replaceAll('\\', '/');
    if (cleanPath.startsWith('http')) return cleanPath;
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    return '${ApiConfig.baseUrl}$cleanPath';
  }
}
