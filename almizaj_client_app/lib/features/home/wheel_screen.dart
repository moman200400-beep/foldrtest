import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:almizaj_client_app/features/auth/user_provider.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});
  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _glowAnimation;

  bool isSpinning = false;
  double _currentAngle = 0.0;
  List<Particle> _particles = [];
  late ConfettiController _confettiController;

  final List<WheelSegment> segments = const [
    WheelSegment(
        icon: '🏆',
        label: 'جائزة كبرى',
        color: Color(0xFFFFD700),
        prize: 'جائزة كبرى',
        darkColor: Color(0xFFB8860B)),
    WheelSegment(
        icon: '🚚',
        label: 'شحن مجاني',
        color: Color(0xFF10B981),
        prize: 'شحن مجاني',
        darkColor: Color(0xFF065F46)),
    WheelSegment(
        icon: '🔧',
        label: 'ضمان مجاني',
        color: Color(0xFFF59E0B),
        prize: 'ضمان مجاني',
        darkColor: Color(0xFF92400E)),
    WheelSegment(
        icon: '💰',
        label: '5% خصم',
        color: Color(0xFFEF4444),
        prize: '5% خصم',
        darkColor: Color(0xFF991B1B)),
    WheelSegment(
        icon: '💎',
        label: '20% خصم',
        color: Color(0xFF6366F1),
        prize: '20% خصم',
        darkColor: Color(0xFF3730A3)),
    WheelSegment(
        icon: '🎁',
        label: '10% خصم',
        color: Color(0xFFEC4899),
        prize: '10% خصم',
        darkColor: Color(0xFF9D174D)),
  ];

  int get targetSegmentIndex => segments.indexWhere((s) => s.prize == '5% خصم');

  @override
  void initState() {
    super.initState();

    _wheelController = AnimationController(vsync: this);
    _wheelController.duration = const Duration(milliseconds: 4500);
    _wheelController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => isSpinning = false);
        _triggerWinParticles();
        _confettiController.play();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showPrizeDialog();
        });
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _particleController.addListener(() {
      if (mounted) setState(() {});
    });

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerWinParticles() {
    final rng = Random();
    _particles = List.generate(
        30,
        (i) => Particle(
              x: rng.nextDouble(),
              y: rng.nextDouble() * 0.5 + 0.25,
              vx: (rng.nextDouble() - 0.5) * 0.8,
              vy: -(rng.nextDouble() * 0.6 + 0.4),
              color: segments[targetSegmentIndex]
                  .color
                  .withValues(alpha: rng.nextDouble() * 0.6 + 0.4),
              size: rng.nextDouble() * 8 + 4,
            ));
    _particleController.forward(from: 0);
  }

  void _spin() {
    if (isSpinning) return;

    final user = Provider.of<UserProvider>(context, listen: false);

    if (user.hasSpunWheel) {
      _showMessage('لقد استخدمت فرصتك اليوم!', Icons.schedule);
      return;
    }
    if (!user.canSpinWheel) {
      _showMessage('أكمل طلباً بقيمة 100 ريال فأكثر للحصول على فرصتك',
          Icons.shopping_cart_outlined);
      return;
    }

    HapticFeedback.heavyImpact();
    debugPrint('🔄 بدء الدوران الفعلي');

    setState(() {
      _currentAngle = 0.0;
    });

    final double segmentAngle = 2 * pi / segments.length;
    final double targetMiddle =
        targetSegmentIndex * segmentAngle + segmentAngle / 2;
    final double targetAngle =
        2 * pi * 6 + (-pi / 2 - targetMiddle - _currentAngle);

    _wheelController.reset();
    _wheelController.duration = const Duration(milliseconds: 4500);

    final animation = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(
          parent: _wheelController, curve: const _CustomSpinCurve()),
    );
    int lastSegment = -1;
    animation.addListener(() {
      if (mounted) {
        final currentVal = animation.value % (2 * pi);
        setState(() => _currentAngle = currentVal);
        final currentSegmentIndex = ((currentVal + pi / 2) / segmentAngle).floor() % segments.length;
        if (lastSegment != currentSegmentIndex && animation.value > 0.1) {
          lastSegment = currentSegmentIndex;
          HapticFeedback.selectionClick();
        }
      }
    });

    setState(() => isSpinning = true);
    _wheelController.forward().then((_) {
      debugPrint('✅ انتهى الدوران');
    }).catchError((e) {
      debugPrint('❌ خطأ في الدوران: $e');
    });
  }

  void _showPrizeDialog() {
    final prizeSegment = segments[targetSegmentIndex];
    Provider.of<UserProvider>(context, listen: false).setWheelSpun(0.05);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  prizeSegment.darkColor.withValues(alpha: 0.4)
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: prizeSegment.color.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: prizeSegment.color.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5)
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (int i = 0; i < 5; i++) ...[
                    Icon(Icons.star,
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.6 + i * 0.08),
                        size: 14 + i * 2.0),
                    if (i < 4) const SizedBox(width: 4),
                  ],
                ]),
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      prizeSegment.color.withValues(alpha: 0.3),
                      prizeSegment.darkColor.withValues(alpha: 0.1)
                    ]),
                    border: Border.all(
                        color: prizeSegment.color.withValues(alpha: 0.6),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: prizeSegment.color.withValues(alpha: 0.4),
                          blurRadius: 20)
                    ],
                  ),
                  child: Center(
                      child: Text(prizeSegment.icon,
                          style: const TextStyle(fontSize: 46))),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(colors: [
                    prizeSegment.color,
                    Colors.white,
                    prizeSegment.color
                  ]).createShader(b),
                  child: const Text('🎉 مبروك عليك!',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Tajawal')),
                ),
                const SizedBox(height: 8),
                Text('لقد فزت بـ',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      prizeSegment.color.withValues(alpha: 0.25),
                      prizeSegment.darkColor.withValues(alpha: 0.15)
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: prizeSegment.color.withValues(alpha: 0.5)),
                  ),
                  child: Text(prizeSegment.prize,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: prizeSegment.color,
                          fontFamily: 'Tajawal')),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: prizeSegment.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('رائع! 🎊',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String msg, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')))
      ]),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final canSpin = !user.hasSpunWheel && user.canSpinWheel;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: _StarfieldPainter()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // جعل حجم العجلة 80% من عرض الشاشة بحد أقصى 320
                  double wheelSize = constraints.maxWidth * 0.8;
                  if (wheelSize > 320) wheelSize = 320;

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.12))),
                                    child: const Icon(Icons.arrow_back_ios_new,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                                const Expanded(
                                  child: Text('عجلة الحظ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Tajawal',
                                          fontSize: 20)),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFFFD700)
                                              .withValues(alpha: 0.3))),
                                  child: const Center(
                                      child: Text('🎡',
                                          style: TextStyle(fontSize: 20))),
                                ),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (canSpin
                                                ? const Color(0xFF8B5CF6)
                                                : Colors.grey)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: (canSpin
                                                    ? const Color(0xFF8B5CF6)
                                                    : Colors.grey)
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                                canSpin
                                                    ? Icons.check_circle_outline
                                                    : Icons.schedule,
                                                color: canSpin
                                                    ? const Color(0xFF8B5CF6)
                                                    : Colors.grey,
                                                size: 16),
                                            const SizedBox(height: 2),
                                            Text(canSpin ? 'متاح' : 'مستخدم',
                                                style: TextStyle(
                                                    fontSize: 9,
                                                    color: canSpin
                                                        ? const Color(
                                                            0xFF8B5CF6)
                                                        : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Tajawal')),
                                          ]),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                        width: 1,
                                        height: 36,
                                        color: Colors.white
                                            .withValues(alpha: 0.12)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: segments
                                              .map((seg) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 6),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: seg.color
                                                            .withValues(
                                                                alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                            color: seg.color
                                                                .withValues(
                                                                    alpha:
                                                                        0.35)),
                                                      ),
                                                      child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(seg.icon,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            13)),
                                                            const SizedBox(
                                                                width: 4),
                                                            Text(seg.label,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: seg
                                                                        .color,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontFamily:
                                                                        'Tajawal')),
                                                          ]),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // السهم
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (_, __) => Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: _glowAnimation.value),
                                size: 44,
                                shadows: [
                                  Shadow(
                                      color: const Color(0xFFEF4444).withValues(
                                          alpha: _glowAnimation.value * 0.8),
                                      blurRadius: 20)
                                ],
                              ),
                            ),
                            // العجلة
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (_, child) => Container(
                                width: wheelSize,
                                height: wheelSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withValues(
                                          alpha: _glowAnimation.value * 0.5),
                                      blurRadius: 50,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withValues(
                                          alpha: _glowAnimation.value * 0.3),
                                      blurRadius: 80,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                              child:
                                  Stack(alignment: Alignment.center, children: [
                                Container(
                                  width: wheelSize,
                                  height: wheelSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(colors: [
                                      const Color(0xFFFFD700)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFFFF6B6B)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFF8B5CF6)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFF10B981)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFFFFD700)
                                          .withValues(alpha: 0.8),
                                    ]),
                                  ),
                                ),
                                Container(
                                  width: wheelSize - 14,
                                  height: wheelSize - 14,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF0D0D1A)),
                                ),
                                Transform.rotate(
                                  angle: _currentAngle,
                                  child: CustomPaint(
                                    size: Size(wheelSize - 26, wheelSize - 26),
                                    painter: WheelPainter(segments: segments),
                                  ),
                                ),
                                // زر GO
                                Positioned.fill(
                                  child: Center(
                                    child: GestureDetector(
                                      onTap:
                                          canSpin && !isSpinning ? _spin : null,
                                      child: AnimatedBuilder(
                                        animation: _glowAnimation,
                                        builder: (_, __) => Container(
                                          width: wheelSize * 0.22,
                                          height: wheelSize * 0.22,
                                          constraints: const BoxConstraints(
                                              minWidth: 50, minHeight: 50),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const RadialGradient(
                                                colors: [
                                                  Colors.white,
                                                  Color(0xFFE2E8F0)
                                                ]),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                    alpha: isSpinning
                                                        ? 0.6
                                                        : _glowAnimation.value *
                                                            0.4),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              isSpinning ? '...' : 'GO',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  color: canSpin
                                                      ? const Color(0xFF8B5CF6)
                                                      : Colors.grey,
                                                  fontSize: wheelSize * 0.08),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 28),
                            // زر الدوران السفلي
                            GestureDetector(
                              onTap: isSpinning || !canSpin ? null : _spin,
                              child: AnimatedBuilder(
                                animation: _glowAnimation,
                                builder: (_, child) => Container(
                                  height: 58,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 48),
                                  decoration: BoxDecoration(
                                    gradient: canSpin
                                        ? const LinearGradient(
                                            colors: [
                                                Color(0xFF8B5CF6),
                                                Color(0xFF6366F1)
                                              ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight)
                                        : LinearGradient(colors: [
                                            Colors.grey.shade800,
                                            Colors.grey.shade700
                                          ]),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: canSpin
                                        ? [
                                            BoxShadow(
                                                color: const Color(0xFF8B5CF6)
                                                    .withValues(
                                                        alpha: _glowAnimation
                                                                .value *
                                                            0.7),
                                                blurRadius: 25,
                                                spreadRadius: 2),
                                          ]
                                        : [],
                                    border: Border.all(
                                        color: canSpin
                                            ? const Color(0xFFA78BFA)
                                                .withValues(alpha: 0.5)
                                            : Colors.transparent),
                                  ),
                                  child: child,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSpinning)
                                      const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                    else
                                      const Text('🎰',
                                          style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 12),
                                    Text(
                                      isSpinning
                                          ? 'جاري الدوران...'
                                          : (canSpin
                                              ? 'ادور وأربح!'
                                              : 'غير متاح'),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Tajawal'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.hasSpunWheel
                                  ? '⏰ عد غداً للحصول على فرصة جديدة'
                                  : '✨ مرة واحدة فقط في اليوم',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                  fontFamily: 'Tajawal'),
                            ),
                            // مسافة إضافية في الأسفل لتفادي القص
                            SizedBox(height: constraints.maxHeight * 0.05),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_particles.isNotEmpty)
              IgnorePointer(
                child: CustomPaint(
                  size: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  painter: ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value),
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // down
                maxBlastForce: 20,
                minBlastForce: 5,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomSpinCurve extends Curve {
  const _CustomSpinCurve();
  @override
  double transformInternal(double t) {
    if (t < 0.7) {
      return Curves.easeIn.transform(t / 0.7) * 0.85;
    } else {
      return 0.85 + Curves.easeOut.transform((t - 0.7) / 0.3) * 0.15;
    }
  }
}

class WheelSegment {
  final String icon;
  final String label;
  final Color color;
  final Color darkColor;
  final String prize;
  const WheelSegment(
      {required this.icon,
      required this.label,
      required this.color,
      required this.prize,
      required this.darkColor});
}

class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;
  WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final double anglePerSeg = 2 * pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * anglePerSeg - pi / 2;
      final seg = segments[i];

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1,
          colors: [seg.color, seg.darkColor],
          stops: const [0.3, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, anglePerSeg, true, paint);

      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, anglePerSeg, true, borderPaint);

      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 1.5;
      final lineEnd = Offset(
        center.dx + radius * cos(startAngle),
        center.dy + radius * sin(startAngle),
      );
      canvas.drawLine(center, lineEnd, linePaint);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + anglePerSeg / 2);
      canvas.translate(radius * 0.60, 0);
      canvas.rotate(pi / 2);

      final shadowSpan = TextSpan(
        text: '${seg.icon}\n${seg.label}',
        style: TextStyle(
            color: Colors.black.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.4),
      );
      final shadowPainter =
          TextPainter(text: shadowSpan, textDirection: TextDirection.rtl)
            ..layout();
      shadowPainter.paint(canvas,
          Offset(-shadowPainter.width / 2 + 1, -shadowPainter.height / 2 + 1));

      final textSpan = TextSpan(
        text: '${seg.icon}\n${seg.label}',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.4),
      );
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.rtl)
            ..layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 1, outerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  double x, y, vx, vy, size;
  Color color;
  Particle(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.size,
      required this.color});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x + p.vx * progress) * size.width;
      final y =
          (p.y + p.vy * progress + 0.5 * 9.8 * progress * progress * 0.1) *
              size.height;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - progress * 0.5),
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StarfieldPainter extends CustomPainter {
  final List<Offset> _stars = List.generate(80, (i) {
    final rng = Random(i * 137);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });
  final List<double> _sizes =
      List.generate(80, (i) => Random(i * 31).nextDouble() * 2.5 + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final alpha = Random(i * 53).nextDouble() * 0.5 + 0.15;
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        _sizes[i],
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
