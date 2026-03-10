import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:almizaj_client_app/features/auth/user_provider.dart';
import 'package:almizaj_client_app/features/auth/auth_screen.dart';
import 'package:almizaj_client_app/features/profile/addresses_screen.dart';
import 'package:almizaj_client_app/features/home/wheel_screen.dart';
import 'package:almizaj_client_app/core/network/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notificationsEnabled = true;
  bool offersEnabled = true;
  bool biometricEnabled = false;
  int orderCount = 0;
  String whatsappNumber = '';

  final LocalAuthentication auth = LocalAuthentication();
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  double _gyroX = 0;
  double _gyroY = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    checkBiometricStatus();

    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        _gyroX -= event.y * 0.05;
        _gyroY -= event.x * 0.05;
        _gyroX = _gyroX.clamp(-0.2, 0.2);
        _gyroY = _gyroY.clamp(-0.2, 0.2);
      });
    });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }

  Future<void> checkBiometricStatus() async {
    // In a real app, load from SharedPreferences. Defaulting to false.
    setState(() => biometricEnabled = false);
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      try {
        final canCheck = await auth.canCheckBiometrics;
        if (!mounted) return;
        if (!canCheck) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البصمة غير متوفرة في جهازك.')));
          return;
        }
        final authenticated = await auth.authenticate(
          localizedReason: 'قم بتأكيد هويتك لتفعيل الدخول السريع',
          biometricOnly: true,
        );
        if (authenticated) {
          setState(() => biometricEnabled = true);
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      setState(() => biometricEnabled = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false);
      final phone = user.phone.isNotEmpty ? user.phone : 'guest';
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/my_orders?uid=$phone'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['ok'] == true && mounted) {
          setState(() => orderCount = (data['orders'] as List).length);
        }
      }
      final res2 = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/home'))
          .timeout(const Duration(seconds: 5));
      if (res2.statusCode == 200) {
        final data2 = json.decode(utf8.decode(res2.bodyBytes));
        if (mounted) {
          setState(() => whatsappNumber = data2['settings']?['whatsapp'] ?? '');
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final userName = user.name ?? 'عميل المزاج';
    final userPhone = user.phone ?? '05xxxxxxxx';
    final userEmail = user.email ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 210,
              pinned: true,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFEC4899),
                        Color(0xFFA855F7),
                        Color(0xFF8B5CF6)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '؟',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Tajawal')),
                        const SizedBox(height: 4),
                        Text(userPhone,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontFamily: 'Tajawal')),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text('حسابي',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Tajawal')),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── إحصائيات ──
                    Row(children: [
                      _stat('$orderCount', 'طلبات', FontAwesomeIcons.boxOpen,
                          const Color(0xFFEC4899)),
                      const SizedBox(width: 10),
                      _stat('0', 'مفضلة', FontAwesomeIcons.heart,
                          const Color(0xFFA855F7)),
                      const SizedBox(width: 10),
                      const SizedBox(width: 10),
                      Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(_gyroX)
                          ..rotateY(_gyroY),
                        alignment: FractionalOffset.center,
                        child: _stat('0', 'نقاط', FontAwesomeIcons.star,
                            const Color(0xFF06B6D4)),
                      ),
                    ]).animate().fade().slideY(begin: 0.5, end: 0, duration: 400.ms),

                    const SizedBox(height: 22),
                    _sectionTitle('نظرة على إنفاقك 📊', Icons.insights),
                    _buildSpendingChart().animate().fade().slideY(begin: 0.5, end: 0, duration: 500.ms, delay: 100.ms),

                    const SizedBox(height: 22),
                    _sectionTitle('بياناتي الشخصية', Icons.person_outline),
                    _card([
                      _infoRow(Icons.person_outline, 'الاسم', userName,
                          onEdit: () => _editField(
                              context,
                              'الاسم',
                              userName,
                              (v) => Provider.of<UserProvider>(context,
                                      listen: false)
                                  .updateName(v))),
                      _div(),
                      _infoRow(Icons.phone_outlined, 'الجوال', userPhone,
                          onEdit: () => _editField(
                              context,
                              'رقم الجوال',
                              userPhone,
                              (v) => Provider.of<UserProvider>(context,
                                      listen: false)
                                  .updatePhone(v))),
                      _div(),
                      _infoRow(Icons.email_outlined, 'البريد',
                          userEmail.isNotEmpty ? userEmail : 'غير محدد',
                          onEdit: () => _editField(
                              context,
                              'البريد',
                              userEmail,
                              (v) => Provider.of<UserProvider>(context,
                                      listen: false)
                                  .updateEmail(v))),
                    ]),

                    const SizedBox(height: 18),
                    _sectionTitle('عناوين التوصيل', Icons.location_on_outlined),
                    _card([_addrTile()]),

                    const SizedBox(height: 18),
                    _sectionTitle('وسائل الدفع', Icons.payment_outlined),
                    _card([
                      _tile(Icons.credit_card_outlined, 'بطاقة بنكية',
                          'أضف بطاقتك', const Color(0xFF3B82F6),
                          showArrow: true),
                      _div(),
                      _tile(
                          Icons.apple, 'Apple Pay', 'غير مفعّل', Colors.black),
                    ]),

                    const SizedBox(height: 18),
                    _sectionTitle('الإشعارات', Icons.notifications_outlined),
                    _card([
                      _switchRow(
                          Icons.notifications_outlined,
                          'تفعيل الإشعارات',
                          const Color(0xFF8B5CF6),
                          notificationsEnabled,
                          (v) => setState(() => notificationsEnabled = v)),
                      _div(),
                      _switchRow(
                          Icons.local_offer_outlined,
                          'العروض والخصومات',
                          const Color(0xFF10B981),
                          offersEnabled,
                          (v) => setState(() => offersEnabled = v)),
                    ]),

                    const SizedBox(height: 18),
                    _sectionTitle('الأمان', Icons.security_outlined),
                    _card([
                      _switchRow(
                          Icons.fingerprint,
                          'الدخول السريع (بالبصمة)',
                          const Color(0xFF3B82F6),
                          biometricEnabled,
                          (v) => _toggleBiometrics(v)),
                      _div(),
                      _tile(Icons.lock_outline, 'تغيير كلمة المرور', '',
                          const Color(0xFFF59E0B),
                          showArrow: true),
                      _div(),
                      _tile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', '',
                          Colors.white54,
                          showArrow: true),
                      _div(),
                      _tile(Icons.description_outlined, 'الشروط والأحكام', '',
                          Colors.white54,
                          showArrow: true),
                    ]).animate().fade().slideY(begin: 0.2, duration: 400.ms),

                    const SizedBox(height: 18),
                    _sectionTitle('مميزات', Icons.auto_awesome_outlined),
                    _card([_wheelTile()]),

                    const SizedBox(height: 18),
                    _sectionTitle('الدعم', Icons.help_outline),
                    _card([
                      _waTile(),
                      _div(),
                      _tile(Icons.info_outline, 'عن التطبيق', 'الإصدار 1.0.0',
                          const Color(0xFF94A3B8)),
                    ]),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('تسجيل الخروج',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──

  Widget _stat(String value, String label, IconData icon, Color color) =>
      Expanded(
        child: GlassContainer(
          borderRadius: 14,
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            FaIcon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'Tajawal')),
          ]),
        ),
      );

  Widget _sectionTitle(String title, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 2),
        child: Row(children: [
          Icon(icon, size: 16, color: const Color(0xFFEC4899)),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal')),
        ]),
      );

  Widget _card(List<Widget> ch) => GlassContainer(
        borderRadius: 16,
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        child: Column(children: ch),
      );

  Widget _infoRow(IconData icon, String label, String value,
          {VoidCallback? onEdit}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white54, fontFamily: 'Tajawal')),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w600)),
              ])),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('تعديل',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B5CF6),
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      );

  Widget _tile(IconData icon, String title, String subtitle, Color c,
          {bool showArrow = false}) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: c, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Tajawal')),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Tajawal'))
            : null,
        trailing: showArrow
            ? const Icon(Icons.arrow_forward_ios,
                size: 13, color: Colors.white54)
            : null,
        onTap: () {},
      );

  Widget _switchRow(IconData icon, String title, Color c, bool val,
          ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Tajawal'))),
          Switch(
              value: val,
              onChanged: onChange,
              activeThumbColor: Colors.white,
              activeTrackColor: c,
              inactiveTrackColor: Colors.white12,
              inactiveThumbColor: Colors.white54),
        ]),
      );

  Widget _addrTile() => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.location_on_outlined,
              color: Color(0xFF8B5CF6), size: 20),
        ),
        title: const Text('عناوين التوصيل',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Tajawal')),
        subtitle: const Text('إضافة وإدارة عناوينك',
            style: TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Tajawal')),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 13, color: Colors.white54),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddressesScreen())),
      );

  Widget _waTile() => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.chat_outlined,
              color: Color(0xFF25D366), size: 20),
        ),
        title: const Text('تواصل معنا واتساب',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Tajawal')),
        subtitle: Text(
            whatsappNumber.isNotEmpty ? whatsappNumber : 'اضغط للتواصل',
            style: const TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Tajawal')),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 13, color: Colors.white54),
        onTap: () {
          final phoneNum = whatsappNumber.isNotEmpty
              ? whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '')
          : '';
          final msg = Uri.encodeComponent('السلام عليكم، أحتاج مساعدة');
          final waUrl = Uri.parse('https://wa.me/966$phoneNum?text=$msg');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'واتساب: ${whatsappNumber.isNotEmpty ? whatsappNumber : "غير محدد"}'),
            backgroundColor: const Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'فتح',
              textColor: Colors.white,
              onPressed: () {
                debugPrint('WhatsApp URL: $waUrl');
              },
            ),
          ));
        },
      );

  Widget _wheelTile() => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.casino_outlined,
              color: Color(0xFFF59E0B), size: 20),
        ),
        title: const Text('عجلة الحظ 🎰',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Tajawal')),
        subtitle: const Text('العب واربح مكافآت',
            style: TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'Tajawal')),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 13, color: Colors.white54),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const WheelScreen())),
      );

  Widget _div() => const Divider(
      height: 1, indent: 66, endIndent: 16, color: Colors.white12);

  Widget _buildSpendingChart() {
    return GlassContainer(
      borderRadius: 16,
      backgroundColor: Colors.white.withValues(alpha: 0.02),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (val, meta) {
                  final titles = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
                  if (val.toInt() >= 0 && val.toInt() < titles.length) {
                    return Text(titles[val.toInt()], style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Tajawal'));
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: 600,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 150),
                FlSpot(1, 280),
                FlSpot(2, 220),
                FlSpot(3, 400),
                FlSpot(4, 300),
                FlSpot(5, 550),
              ],
              isCurved: true,
              color: const Color(0xFF8B5CF6),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editField(BuildContext context, String label, String current,
      Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          title: Text('تعديل $label',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Tajawal')),
          content: TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  hintText: label,
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white54, fontFamily: 'Tajawal'))),
            ElevatedButton(
              onPressed: () {
                onSave(ctrl.text.trim());
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('حفظ', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          title: const Text('تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Tajawal')),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟', style: TextStyle(color: Colors.white70, fontFamily: 'Tajawal')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white54, fontFamily: 'Tajawal'))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Provider.of<UserProvider>(context, listen: false).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }
}
