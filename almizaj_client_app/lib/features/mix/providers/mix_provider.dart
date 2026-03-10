import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/mix_models.dart';
import '../../../core/network/api_config.dart';

class MixProvider with ChangeNotifier {
  bool isLoading = false;
  String? error;

  MixSetting? settings;
  List<MixFlavor> flavors = [];
  List<MixMood> moods = [];
  List<MixSize> sizes = [];

  // User Selections
  MixMood? selectedMood;
  List<SelectedFlavor> selectedFlavors = [];
  String strength = 'متوسط'; // خفيف، متوسط، قوي
  MixSize? selectedSize;
  String? savedMixCode;
  String customName = 'خلطتي الخاصة';

  void setStrength(String s) {
    strength = s;
    notifyListeners();
  }

  void setSize(MixSize s) {
    selectedSize = s;
    notifyListeners();
  }

  Future<void> fetchMixData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/mix/data'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          settings = MixSetting.fromJson(data['settings']);
          flavors = (data['flavors'] as List).map((f) => MixFlavor.fromJson(f)).toList();
          moods = (data['moods'] as List).map((m) => MixMood.fromJson(m)).toList();
          sizes = (data['sizes'] as List).map((s) => MixSize.fromJson(s)).toList();
        } else {
          error = "حدث خطأ أثناء جلب البيانات";
        }
      } else {
        error = "فشل الاتصال بالخادم";
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void chooseMood(MixMood mood) {
    selectedMood = mood;
    // Note: Here we could pre-select suggested flavors if needed
    notifyListeners();
  }

  void chooseRandomFlavors() {
    selectedFlavors.clear();
    final randomFlavors = flavors.toList()..shuffle();
    final maxF = settings?.maxFlavors ?? 3;
    final count = randomFlavors.length > maxF ? maxF : randomFlavors.length;
    
    int remainingPercentage = 100;
    for (int i = 0; i < count; i++) {
      int p = (i == count - 1) ? remainingPercentage : (100 ~/ count);
      selectedFlavors.add(SelectedFlavor(flavor: randomFlavors[i], percentage: p));
      remainingPercentage -= p;
    }
    selectedMood = MixMood(id: 0, name: 'فاجئني', icon: '🎲', description: 'خلطة عشوائية مذهلة');
    notifyListeners();
  }

  void addFlavor(MixFlavor flavor) {
    if (selectedFlavors.length >= (settings?.maxFlavors ?? 3)) {
      return; // Reached max
    }
    if (selectedFlavors.any((sf) => sf.flavor.id == flavor.id)) {
      return; // Already added
    }
    selectedFlavors.add(SelectedFlavor(flavor: flavor, percentage: settings?.minPercentage ?? 10));
    _balancePercentages();
    notifyListeners();
  }

  void removeFlavor(int flavorId) {
    selectedFlavors.removeWhere((sf) => sf.flavor.id == flavorId);
    _balancePercentages();
    notifyListeners();
  }

  void updateFlavorPercentage(int flavorId, int percentage) {
    final sf = selectedFlavors.firstWhere((sf) => sf.flavor.id == flavorId);
    sf.percentage = percentage;
    _balancePercentages(lockedFlavorId: flavorId);
    notifyListeners();
  }

  void _balancePercentages({int? lockedFlavorId}) {
    if (selectedFlavors.isEmpty) return;
    int minP = settings?.minPercentage ?? 10;

    if (selectedFlavors.length == 1) {
      selectedFlavors.first.percentage = 100;
      return;
    }

    lockedFlavorId ??= selectedFlavors.last.flavor.id;

    var lockedItem = selectedFlavors.firstWhere((sf) => sf.flavor.id == lockedFlavorId);
    var others = selectedFlavors.where((sf) => sf.flavor.id != lockedFlavorId).toList();

    int minRequiredForOthers = others.length * minP;
    int maxAllowedForLocked = 100 - minRequiredForOthers;

    if (lockedItem.percentage > maxAllowedForLocked) {
      lockedItem.percentage = maxAllowedForLocked;
    }
    if (lockedItem.percentage < minP) {
      lockedItem.percentage = minP;
    }

    int targetSum = 100 - lockedItem.percentage;
    int othersSum = others.fold(0, (s, sf) => s + sf.percentage);

    if (othersSum == 0) {
      int share = targetSum ~/ others.length;
      for (var sf in others) {
        sf.percentage = share;
      }
      others.last.percentage += targetSum - (share * others.length);
    } else {
      double ratio = targetSum / othersSum;
      int allocated = 0;
      for (int i = 0; i < others.length - 1; i++) {
        int newP = (others[i].percentage * ratio).round();
        if (newP < minP) newP = minP;
        if (targetSum - allocated - newP < minP) {
            newP = targetSum - allocated - minP; // preserve minimum for the last element
            if (newP < minP) newP = minP;
        }
        others[i].percentage = newP;
        allocated += newP;
      }
      
      int lastP = targetSum - allocated;
      if (lastP < minP) {
        int deficit = minP - lastP;
        lastP = minP;
        for (int i = others.length - 2; i >= 0 && deficit > 0; i--) {
          int availableToTake = others[i].percentage - minP;
          if (availableToTake > 0) {
            int take = availableToTake > deficit ? deficit : availableToTake;
            others[i].percentage -= take;
            deficit -= take;
          }
        }
      }
      others.last.percentage = lastP;
    }
  }

  double calculateTotalPrice() {
    double base = selectedSize?.price ?? 0.0;
    double extra = selectedFlavors.fold(0.0, (sum, sf) => sum + sf.flavor.basePrice);
    return base + extra;
  }

  Future<bool> saveMix(String? userPhone) async {
    isLoading = true;
    notifyListeners();

    try {
      final payload = {
        "name": customName.isNotEmpty ? customName : 'خلطتي الخاصة',
        "flavors": selectedFlavors.map((sf) => {
          "id": sf.flavor.id,
          "name": sf.flavor.name,
          "percentage": sf.percentage
        }).toList(),
        "strength": strength,
        "size_id": selectedSize?.id,
        "total_price": calculateTotalPrice(),
        "user_phone": userPhone
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/mix/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok']) {
          savedMixCode = data['code'];
          isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  void resetMix() {
    selectedMood = null;
    selectedFlavors.clear();
    strength = 'متوسط';
    selectedSize = null;
    savedMixCode = null;
    customName = 'خلطتي الخاصة';
    notifyListeners();
  }
}
