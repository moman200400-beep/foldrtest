import 'package:flutter/material.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void toggle(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
  }

  int get count => _favoriteIds.length;
}
