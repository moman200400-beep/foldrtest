import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mix_provider.dart';
import '../models/mix_models.dart';
import 'mix_details_screen.dart';

class MixFlavorsScreen extends StatelessWidget {
  const MixFlavorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mixProvider = Provider.of<MixProvider>(context);
    final maxF = mixProvider.settings?.maxFlavors ?? 3;
    final minP = mixProvider.settings?.minPercentage ?? 10;
    final maxP = mixProvider.settings?.maxPercentage ?? 100;
    
    // total selected percent
    int totalP = mixProvider.selectedFlavors.fold(0, (sum, f) => sum + f.percentage);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(mixProvider.selectedMood?.name ?? "خلطتك", style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Selected Flavors List and Sliders
          if (mixProvider.selectedFlavors.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: totalP == 100 ? Colors.green.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('النكهات المختارة', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('$totalP%', style: TextStyle(color: totalP == 100 ? Colors.green : Colors.redAccent, fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ...mixProvider.selectedFlavors.map((sf) => _buildFlavorSlider(context, sf, minP, maxP, mixProvider)),
                ],
              ),
            ),
            
          // Remaining Flavors to choose
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: mixProvider.flavors.length,
              itemBuilder: (context, index) {
                final f = mixProvider.flavors[index];
                final isSelected = mixProvider.selectedFlavors.any((sf) => sf.flavor.id == f.id);
                final isDisabled = !isSelected && mixProvider.selectedFlavors.length >= maxF;

                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      mixProvider.removeFlavor(f.id);
                    } else {
                      if (!isDisabled) mixProvider.addFlavor(f);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: isDisabled ? 0.02 : 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? Colors.purpleAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(f.icon, style: TextStyle(fontSize: 16, color: isDisabled ? Colors.grey : Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              f.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDisabled ? Colors.grey : Colors.white,
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Positioned(
                            top: 5, right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Next Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: mixProvider.selectedFlavors.isNotEmpty && totalP == 100
                    ? () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => MixDetailsScreen()));
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('التالي', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlavorSlider(BuildContext context, SelectedFlavor sf, int minP, int maxP, MixProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(sf.flavor.icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(child: Text(sf.flavor.name, style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 11))),
              Text('${sf.percentage}%', style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          SizedBox(
            height: 15,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.purpleAccent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: Colors.purpleAccent,
                overlayColor: Colors.purple.withValues(alpha: 0.2),
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
              ),
              child: Slider(
                value: sf.percentage.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (val) {
                  provider.updateFlavorPercentage(sf.flavor.id, val.toInt());
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
