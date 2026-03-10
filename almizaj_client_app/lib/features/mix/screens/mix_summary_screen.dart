import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mix_provider.dart';
import '../../cart/cart_provider.dart';

class MixSummaryScreen extends StatefulWidget {
  const MixSummaryScreen({super.key});

  @override
  State<MixSummaryScreen> createState() => _MixSummaryScreenState();
}

class _MixSummaryScreenState extends State<MixSummaryScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final mixProvider = Provider.of<MixProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (_nameController.text.trim().isNotEmpty) {
      mixProvider.customName = _nameController.text.trim();
    }

    // Attempt to save mix to get the code
    final success = await mixProvider.saveMix(null); // Passing null for phone assuming guest initially

    if (!mounted) return;

    if (success && mixProvider.savedMixCode != null) {
      // Add to cart using cart provider logic
      // We pass the Mix Code as ID and a special indicator, UI can read it
      cartProvider.addItem(
        mixProvider.savedMixCode!,
        mixProvider.customName,
        mixProvider.calculateTotalPrice(),
        'mix', // special image indicator
        100, // unlimited stock basically
        1,
      );
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('✨ تمت الإضافة بنجاح', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تم إضافة خلطتك للسلة، يمكنك مشاركتها مع أصدقائك بالكود:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(mixProvider.savedMixCode!, style: const TextStyle(color: Colors.purpleAccent, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst); // Back to home
                mixProvider.resetMix();
              },
              child: const Text('حسناً', style: TextStyle(color: Colors.purpleAccent, fontFamily: 'Tajawal', fontSize: 16)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mixProvider.error ?? 'حدث خطأ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mixProvider = Provider.of<MixProvider>(context);
    final totalPrice = mixProvider.calculateTotalPrice();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ملخص الخلطة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white)),
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
            // Preview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent.withValues(alpha: 0.3), Colors.blueAccent.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome, size: 50, color: Colors.purpleAccent),
                  const SizedBox(height: 10),
                  const Text('مكونات خلطتك السحرية', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  const Divider(color: Colors.white24, height: 30),
                  
                  // Component 1: Flavors
                  ...mixProvider.selectedFlavors.map((sf) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(sf.flavor.icon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(sf.flavor.name, style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
                              ],
                            ),
                            Text('${sf.percentage}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                  
                  const Divider(color: Colors.white24, height: 30),
                  
                  // Component 2: Strength and Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('قوة السحبة', style: TextStyle(color: Colors.grey, fontFamily: 'Tajawal')),
                      Text(mixProvider.strength, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الحجم', style: TextStyle(color: Colors.grey, fontFamily: 'Tajawal')),
                      Text(mixProvider.selectedSize?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Name Input
            const Text('اسم الخلطة (اختياري)', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'مثال: خلطة مزاج الليل',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.purpleAccent)),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Total & Checkout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Tajawal')),
                Text('$totalPrice ر.س', style: const TextStyle(color: Colors.purpleAccent, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: mixProvider.isLoading ? null : () => _submit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: mixProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('إضافة إلى السلة', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
