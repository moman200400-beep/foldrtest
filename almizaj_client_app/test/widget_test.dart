import 'package:flutter_test/flutter_test.dart';
import 'package:almizaj_client_app/main.dart'; // مسار تطبيقك

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // تشغيل تطبيقنا الفاخر في وضع الاختبار
    await tester.pumpWidget(const AlmizajApp(isLoggedIn: false));

    // التأكد من ظهور كلمة "الرئيسية" في شريط التنقل كدليل على عمل التطبيق
    expect(find.text('الرئيسية'), findsWidgets);
  });
}
