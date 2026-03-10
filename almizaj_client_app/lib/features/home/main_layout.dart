import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import 'package:almizaj_client_app/features/cart/cart_provider.dart';
import 'package:almizaj_client_app/features/home/home_screen.dart';
import 'package:almizaj_client_app/features/home/search_screen.dart';
import 'package:almizaj_client_app/features/cart/cart_screen.dart';
import 'package:almizaj_client_app/features/orders/orders_screen.dart';
import 'package:almizaj_client_app/features/profile/profile_screen.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<AnimationController> _controllers;

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(
        icon: FontAwesomeIcons.house,
        activeIcon: FontAwesomeIcons.houseUser,
        label: 'الرئيسية',
        color: Color(0xFFEC4899)),
    _NavItem(
        icon: FontAwesomeIcons.magnifyingGlass,
        activeIcon: FontAwesomeIcons.magnifyingGlassChart,
        label: 'بحث',
        color: Color(0xFFA855F7)),
    _NavItem(
        icon: FontAwesomeIcons.cartShopping,
        activeIcon: FontAwesomeIcons.cartArrowDown,
        label: 'السلة',
        color: Color(0xFFDB2777)),
    _NavItem(
        icon: FontAwesomeIcons.boxOpen,
        activeIcon: FontAwesomeIcons.boxOpen,
        label: 'طلباتي',
        color: Color(0xFF06B6D4)),
    _NavItem(
        icon: FontAwesomeIcons.user,
        activeIcon: FontAwesomeIcons.userCheck,
        label: 'حسابي',
        color: Color(0xFF8B5CF6)),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
        5,
        (i) => AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 220),
            ));
    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    
    if (index == 2) {
      _showCartBottomSheet();
      return;
    }

    _controllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _controllers[index].forward();
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.90,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: const CartScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Dark Luxury Theme
      body: Container(
        color: Colors.transparent,
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.transparent, // transparent to let the body show behind if extending body behind nav, but here we just float it
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 10),
      child: GlassContainer(
        height: 70,
        borderRadius: 35,
        backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.85),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => _buildNavItem(i)),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _items[index];
    final isActive = _currentIndex == index;

    if (index == 2) {
      return _buildCartItem(item, isActive);
    }

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? item.color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              isActive ? item.activeIcon : item.icon,
              size: isActive ? 22 : 20,
              color: isActive ? item.color : Colors.white.withValues(alpha: 0.5),
            ).animate(target: isActive ? 1 : 0).scale(duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack, begin: const Offset(1,1), end: const Offset(1.1,1.1)).shimmer(duration: const Duration(milliseconds: 1000)),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  color: item.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'Tajawal',
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(_NavItem item, bool isActive) {
    return GestureDetector(
      onTap: () => _onTap(2),
      behavior: HitTestBehavior.opaque,
      child: Consumer<CartProvider>(
        builder: (_, cart, __) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 8, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? item.color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              badges.Badge(
                showBadge: cart.itemCount > 0,
                badgeAnimation: const badges.BadgeAnimation.scale(
                  animationDuration: Duration(milliseconds: 200),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Color(0xFFEF4444),
                  padding: EdgeInsets.all(4),
                ),
                badgeContent: Text(
                  '${cart.itemCount}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: FaIcon(
                  isActive ? item.activeIcon : item.icon,
                  size: isActive ? 22 : 20,
                  color: isActive ? item.color : Colors.white.withValues(alpha: 0.5),
                ).animate(target: isActive ? 1 : 0).scale(duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack, begin: const Offset(1,1), end: const Offset(1.1,1.1)).shimmer(duration: const Duration(milliseconds: 1000)),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.color});
}
