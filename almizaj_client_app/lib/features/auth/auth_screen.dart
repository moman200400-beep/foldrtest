import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:almizaj_client_app/core/network/api_config.dart';
import 'package:almizaj_client_app/features/auth/user_provider.dart';
import 'package:almizaj_client_app/features/home/main_layout.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _loginPhone = TextEditingController();
  final _loginPass = TextEditingController();
  bool _loginPassVisible = false;

  final _regName = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPass = TextEditingController();
  final _regConfirm = TextEditingController();
  bool _regPassVisible = false;
  bool _regConfirmVisible = false;

  @override
  void dispose() {
    _loginPhone.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regPhone.dispose();
    _regPass.dispose();
    _regConfirm.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.trim().replaceAll(' ', '');
    return cleaned.length == 10 &&
        cleaned.startsWith('05') &&
        RegExp(r'^[0-9]+$').hasMatch(cleaned);
  }

  void _goHome(String name, String phone,
      {String email = '', String uid = ''}) {
    Provider.of<UserProvider>(context, listen: false)
        .login(name: name, phone: phone, email: email, uid: uid);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainLayout()));
  }

  Future<void> _login() async {
    final phone = _loginPhone.text.trim();
    final pass = _loginPass.text;

    if (phone.isEmpty || pass.isEmpty) {
      _snack('يرجى ملء جميع الحقول', Colors.red);
      return;
    }
    if (!_isValidPhone(phone)) {
      _snack('رقم الجوال يجب أن يكون 10 أرقام ويبدأ بـ 05', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'phone': phone, 'password': pass}),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data['ok'] == true) {
        _goHome(data['name'] ?? 'عميل', phone, uid: data['uid'] ?? '');
      } else {
        _snack(data['error'] ?? 'بيانات غير صحيحة', Colors.red);
      }
    } catch (e) {
      _snack('تعذّر الاتصال بالسيرفر.', Colors.red);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    final name = _regName.text.trim();
    final phone = _regPhone.text.trim();
    final pass = _regPass.text;
    final confirm = _regConfirm.text;

    if (name.isEmpty || phone.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _snack('يرجى ملء جميع الحقول', Colors.red);
      return;
    }
    if (name.length < 3) {
      _snack('الاسم 3 أحرف على الأقل', Colors.orange);
      return;
    }
    if (!_isValidPhone(phone)) {
      _snack('رقم الجوال يجب أن يكون 10 أرقام ويبدأ بـ 05', Colors.orange);
      return;
    }
    if (pass.length < 6) {
      _snack('كلمة المرور 6 أحرف على الأقل', Colors.orange);
      return;
    }
    if (pass != confirm) {
      _snack('كلمتا المرور غير متطابقتين', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'name': name, 'phone': phone, 'password': pass}),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data['ok'] == true) {
        _snack('تم التسجيل بنجاح! 🎉', const Color(0xFF10B981));
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _goHome(name, phone, uid: data['uid'] ?? '');
      } else {
        _snack(data['error'] ?? 'حدث خطأ', Colors.red);
      }
    } catch (_) {
      _snack('تعذّر الاتصال بالسيرفر.', Colors.red);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final storeLogo = userProvider.storeLogo;
    final storeName = userProvider.storeName;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A), // Dark luxury theme
        body: Stack(
          children: [
            // Floating animated background spheres
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
                      const Color(0xFFEC4899).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: 30,
                  duration: 4.seconds,
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
                      const Color(0xFFA855F7).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(
                  begin: 0,
                  end: 40,
                  duration: 5.seconds,
                  curve: Curves.easeInOut),
            ),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Store Logo (Glassmorphic)
                      Center(
                        child: GlassContainer(
                          width: 100,
                          height: 100,
                          borderRadius: 50,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          child: ClipOval(
                            child: storeLogo.isNotEmpty
                                ? Image.network(
                                    userProvider.getFullImageUrl(storeLogo),
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(Icons.storefront,
                                            color: Colors.white, size: 40),
                                  )
                                : const Icon(Icons.storefront,
                                    color: Colors.white, size: 40),
                          ),
                        )
                            .animate()
                            .scale(duration: 600.ms, curve: Curves.easeOutBack),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        storeName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Tajawal'),
                      ).animate().fade().slideY(begin: 0.5, end: 0),
                      const SizedBox(height: 8),
                      Text('رحلة تسوق فاخرة بانتظارك ✨',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 15,
                                  fontFamily: 'Tajawal'))
                          .animate()
                          .fade(delay: 200.ms),
                      const SizedBox(height: 40),

                      // Auth Box (Glassmorphic)
                      GlassContainer(
                        borderRadius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tabs
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Row(children: [
                                  Expanded(child: _tab('تسجيل الدخول', true)),
                                  Expanded(child: _tab('إنشاء حساب', false)),
                                ]),
                              ),
                              const SizedBox(height: 30),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0.05, 0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child)),
                                child:
                                    _isLogin ? _loginForm() : _registerForm(),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: 400.ms).fade(duration: 500.ms).slideY(
                          begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 30),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              _goHome('زائر', 'guest', uid: 'guest'),
                          child: const Text('التصفح بدون حساب ←',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool forLogin) {
    final isActive = _isLogin == forLogin;
    return GestureDetector(
      onTap: () => setState(() => _isLogin = forLogin),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
                fontFamily: 'Tajawal')),
      ),
    );
  }

  Widget _loginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _field(_loginPhone, 'رقم الجوال (05xxxxxxxxx)', Icons.phone_outlined,
            keyboardType: TextInputType.phone, maxLength: 10),
        const SizedBox(height: 14),
        _field(_loginPass, 'كلمة المرور', Icons.lock_outline,
            isPassword: true,
            isVisible: _loginPassVisible,
            onToggle: () =>
                setState(() => _loginPassVisible = !_loginPassVisible)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
              onPressed: () {},
              child: const Text('نسيت كلمة المرور؟',
                  style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12))),
        ),
        const SizedBox(height: 10),
        _btn('تسجيل الدخول', FontAwesomeIcons.rightToBracket, _login),
      ],
    );
  }

  Widget _registerForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        _field(_regName, 'الاسم الكامل', Icons.person_outline),
        const SizedBox(height: 12),
        _field(_regPhone, 'رقم الجوال (05xxxxxxxxx)', Icons.phone_outlined,
            keyboardType: TextInputType.phone, maxLength: 10),
        const SizedBox(height: 12),
        _field(_regPass, 'كلمة المرور', Icons.lock_outline,
            isPassword: true,
            isVisible: _regPassVisible,
            onToggle: () => setState(() => _regPassVisible = !_regPassVisible)),
        const SizedBox(height: 12),
        _field(_regConfirm, 'تأكيد المرور', Icons.lock_outline,
            isPassword: true,
            isVisible: _regConfirmVisible,
            onToggle: () =>
                setState(() => _regConfirmVisible = !_regConfirmVisible)),
        const SizedBox(height: 20),
        _btn('إنشاء الحساب', FontAwesomeIcons.userPlus, _register,
            color: const Color(0xFF10B981)),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool isPassword = false,
      bool isVisible = false,
      VoidCallback? onToggle,
      TextInputType keyboardType = TextInputType.text,
      int? maxLength}) {
    return GlassContainer(
      borderRadius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.03),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(
            fontSize: 14, fontFamily: 'Tajawal', color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon:
              Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      isVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18),
                  onPressed: onToggle)
              : null,
          border: InputBorder.none,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback onPressed,
      {Color? color}) {
    final defaultGradient = const LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: color != null ? null : defaultGradient,
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (color ?? const Color(0xFFEC4899)).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  FaIcon(icon, size: 16),
                  const SizedBox(width: 10),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Tajawal'))
                ]),
        ),
      ),
    );
  }
}
