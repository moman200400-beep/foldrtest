import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/mix_provider.dart';
import 'mix_flavors_screen.dart';

class MixIntroScreen extends StatefulWidget {
  const MixIntroScreen({super.key});

  @override
  State<MixIntroScreen> createState() => _MixIntroScreenState();
}

class _MixIntroScreenState extends State<MixIntroScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MixProvider>(context, listen: false).fetchMixData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mixProvider = Provider.of<MixProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('مصمم خصيصاً لمزاجك',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: mixProvider.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.purpleAccent))
          : mixProvider.error != null
              ? Center(
                  child: Text(mixProvider.error!,
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Tajawal')))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12),
                          child: Text(
                            'اختر مزاجك اليوم.. 🎯',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.9,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: mixProvider.moods.length,
                              itemBuilder: (context, index) {
                                final mood = mixProvider.moods[index];
                                final isRandom = mood.name == 'فاجئني';

                                // Colors for each mood card
                                final List<List<Color>> gradients = [
                                  [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
                                  [const Color(0xFFEC4899), const Color(0xFFF472B6)],
                                  [const Color(0xFF10B981), const Color(0xFF34D399)],
                                  [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
                                  [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                                  [const Color(0xFFEF4444), const Color(0xFFF87171)],
                                ];
                                final gradient =
                                    gradients[index % gradients.length];

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (isRandom) {
                                      mixProvider.chooseRandomFlavors();
                                    } else {
                                      mixProvider.chooseMood(mood);
                                    }
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) =>
                                                MixFlavorsScreen()));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          gradient[0].withValues(alpha: 0.15),
                                          gradient[1].withValues(alpha: 0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: gradient[0].withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: gradient[0]
                                                .withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(mood.icon,
                                                style: const TextStyle(
                                                    fontSize: 22)),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          mood.name,
                                          style: TextStyle(
                                            color: isRandom
                                                ? Colors.purpleAccent
                                                : Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
