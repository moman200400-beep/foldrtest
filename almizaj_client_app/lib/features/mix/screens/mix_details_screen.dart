import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mix_provider.dart';
import 'mix_summary_screen.dart';

class MixDetailsScreen extends StatelessWidget {
  final List<String> strengths = const ['خفيف', 'متوسط', 'قوي'];

  const MixDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mixProvider = Provider.of<MixProvider>(context);

    // Initial default values if not set
    if (mixProvider.selectedSize == null && mixProvider.sizes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mixProvider.setSize(mixProvider.sizes.first);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('تفاصيل الخلطة',
            style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'قوة النكهة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: strengths.map((s) {
                final isSelected = mixProvider.strength == s;
                return GestureDetector(
                  onTap: () {
                    mixProvider.setStrength(s);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.purpleAccent.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected
                              ? Colors.purpleAccent
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.purpleAccent : Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            const Text(
              'حجم الطلب',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal'),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mixProvider.sizes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final size = mixProvider.sizes[index];
                final isSelected = mixProvider.selectedSize?.id == size.id;

                return GestureDetector(
                  onTap: () {
                    mixProvider.setSize(size);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.purpleAccent.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: isSelected
                              ? Colors.purpleAccent
                              : Colors.transparent,
                          width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                                size.type == 'head'
                                    ? Icons.smoking_rooms
                                    : Icons.scale,
                                color: isSelected
                                    ? Colors.purpleAccent
                                    : Colors.grey),
                            const SizedBox(width: 15),
                            Text(size.name,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Tajawal',
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ],
                        ),
                        Text('${size.price} ر.س',
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.purpleAccent
                                    : Colors.white,
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: mixProvider.selectedSize != null
                    ? () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => MixSummaryScreen()));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('متابعة',
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
