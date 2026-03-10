import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_screen.dart';
import 'features/home/main_layout.dart';
import 'features/cart/cart_provider.dart';
import 'features/auth/user_provider.dart';
import 'features/products/favorites_provider.dart';
import 'features/mix/providers/mix_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة UserProvider وقراءة الذاكرة المحفوظة
  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();

  // تحميل إعدادات المتجر (الشعار، اسم المتجر) من السيرفر
  await userProvider.fetchStoreSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => MixProvider()),
      ],
      child: AlmizajApp(isLoggedIn: userProvider.isLoggedIn),
    ),
  );
}

class AlmizajApp extends StatelessWidget {
  final bool isLoggedIn;

  const AlmizajApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المزاج الأول',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'AE')],
      locale: const Locale('ar', 'AE'),
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.tajawalTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        primaryColor: const Color(0xFF8B5CF6),
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1B4B),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'Tajawal',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0D0D1A),
          selectedItemColor: Color(0xFF8B5CF6),
          unselectedItemColor: Color(0xFF4A4A6A),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
              fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 11),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        cardColor: const Color(0xFF1A1A2E),
        dividerColor: const Color(0xFF1E1E3A),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A1A2E)),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: isLoggedIn ? const MainLayout() : const AuthScreen(),
    );
  }
}
