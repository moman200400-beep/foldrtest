class MixFlavor {
  final int id;
  final String name;
  final String icon;
  final String category;
  final double basePrice;

  MixFlavor({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.basePrice,
  });

  factory MixFlavor.fromJson(Map<String, dynamic> json) {
    return MixFlavor(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      category: json['category'],
      basePrice: (json['base_price'] as num).toDouble(),
    );
  }
}

class MixMood {
  final int id;
  final String name;
  final String icon;
  final String description;

  MixMood({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory MixMood.fromJson(Map<String, dynamic> json) {
    return MixMood(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      description: json['description'] ?? '',
    );
  }
}

class MixSize {
  final int id;
  final String name;
  final String type; // head or weight
  final double price;

  MixSize({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
  });

  factory MixSize.fromJson(Map<String, dynamic> json) {
    return MixSize(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class MixSetting {
  final int maxFlavors;
  final int minPercentage;
  final int maxPercentage;

  MixSetting({
    required this.maxFlavors,
    required this.minPercentage,
    required this.maxPercentage,
  });

  factory MixSetting.fromJson(Map<String, dynamic> json) {
    return MixSetting(
      maxFlavors: json['max_flavors'] ?? 3,
      minPercentage: json['min_percentage'] ?? 10,
      maxPercentage: json['max_percentage'] ?? 100,
    );
  }
}

class SelectedFlavor {
  final MixFlavor flavor;
  int percentage;

  SelectedFlavor({
    required this.flavor,
    this.percentage = 0,
  });
}
