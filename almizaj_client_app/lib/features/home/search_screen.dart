import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:almizaj_client_app/core/network/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:almizaj_client_app/shared/widgets/product_card.dart';
import 'package:almizaj_client_app/shared/widgets/loading_skeleton.dart';
import 'package:almizaj_client_app/shared/widgets/glass_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';

  List<dynamic> allProducts = [];
  List<dynamic> searchResults = [];
  List<String> recentSearches = [];

  String currentSort = 'الأحدث';

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastRecognizedWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadRecentSearches();
    _fetchAllProducts();
  }

  String getImageUrl(String path) {
    if (path.isEmpty) {
      return 'https://via.placeholder.com/400x200?text=No+Image';
    }
    String cleanPath = path.replaceAll('\\', '/');
    if (cleanPath.startsWith('http')) {
      return cleanPath;
    }
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    return '${ApiConfig.baseUrl}$cleanPath';
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    if (term.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!recentSearches.contains(term)) {
      recentSearches.insert(0, term);
      if (recentSearches.length > 5) {
        recentSearches.removeLast();
      }
      await prefs.setStringList('recent_searches', recentSearches);
    }
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      recentSearches.clear();
    });
  }

  Future<void> _fetchAllProducts() async {
    try {
      setState(() {
        isLoading = true;
      });
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/home'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['ok'] == true) {
          if (mounted) {
            setState(() {
              allProducts = data['products'] ?? [];
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    final searchWords = query.toLowerCase().trim().split(RegExp(r'\s+'));

    final results = allProducts.where((p) {
      final name = p['name'].toString().toLowerCase();
      final category = p['category']?.toString().toLowerCase() ?? '';

      // Fuzzy match: check if all words exist in the name or category
      bool matchesName = true;
      bool matchesCategory = true;

      for (final word in searchWords) {
        if (!name.contains(word)) matchesName = false;
        if (!category.contains(word)) matchesCategory = false;
      }
      return matchesName || matchesCategory;
    }).toList();

    _applySorting(results);
  }

  void _applySorting(List<dynamic> listToSort) {
    if (currentSort == 'الأرخص') {
      listToSort.sort(
        (a, b) => (a['price'] as num).compareTo(b['price'] as num),
      );
    } else if (currentSort == 'الأغلى') {
      listToSort.sort(
        (a, b) => (b['price'] as num).compareTo(a['price'] as num),
      );
    } else if (currentSort == 'الأحدث') {
      listToSort.sort((a, b) => (b['id'] as num).compareTo(a['id'] as num));
    }

    setState(() {
      searchResults = listToSort;
    });
  }

  void _onSortChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        currentSort = newValue;
      });
      if (_searchController.text.isNotEmpty) {
        _onSearchChanged(_searchController.text);
      } else {
        final all = List<dynamic>.from(allProducts);
        _applySorting(all);
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_lastRecognizedWords.isNotEmpty) {
              _onSearchChanged(_lastRecognizedWords);
              _saveSearchTerm(_lastRecognizedWords);
            }
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              _lastRecognizedWords = val.recognizedWords;
              _onSearchChanged(val.recognizedWords);
            });
          },
          localeId: 'ar_SA',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'البحث المتقدم 🔎',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Tajawal',
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        borderRadius: 15,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.2)),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onSubmitted: (val) => _saveSearchTerm(val),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Tajawal',
                          ),
                          decoration: InputDecoration(
                            hintText: 'عن ماذا تبحث اليوم؟...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF64748B),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF94A3B8),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: _isListening ? const Color(0xFFEC4899) : const Color(0xFF94A3B8),
                                    ),
                                    onPressed: _listen,
                                  ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.sliders,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () {
                          _showFilterBottomSheet(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_searchController.text.isEmpty &&
              recentSearches.isNotEmpty &&
              searchResults.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'عمليات البحث الأخيرة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearRecentSearches,
                          child: const Text(
                            'مسح الكل',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: recentSearches.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final term = recentSearches[index];
                          return Dismissible(
                            key: Key(term),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              setState(() {
                                recentSearches.removeAt(index);
                              });
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setStringList(
                                  'recent_searches', recentSearches);
                              HapticFeedback.lightImpact();
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: GlassContainer(
                              borderRadius: 15,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                              child: ListTile(
                                minLeadingWidth: 20,
                                leading: const Icon(Icons.history,
                                    color: Colors.white54, size: 20),
                                title: Text(term,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Tajawal')),
                                trailing: const Icon(Icons.north_west,
                                    color: Colors.white30, size: 16),
                                onTap: () {
                                  _searchController.text = term;
                                  _onSearchChanged(term);
                                },
                              ),
                            ).animate().fade().slideX(
                                begin: 0.1,
                                end: 0,
                                delay: Duration(milliseconds: 50 * index)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isLoading)
            const Expanded(child: HomeSkeletonLoader())
          else if (_searchController.text.isNotEmpty && searchResults.isEmpty)
            Expanded(
              child: Center(
                child: GlassContainer(
                  borderRadius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.2)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.boxOpen,
                          size: 60,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'لم نجد أي منتج يطابق بحثك!',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'حاول استخدام كلمات مختلفة.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.02, duration: 2.seconds),
              ),
            )
          else if (searchResults.isNotEmpty)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: searchResults[index],
                    getImageUrl: getImageUrl,
                    searchQuery: _searchController.text,
                    onAddToCart: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم إضافة ${searchResults[index]['name']} للسلة!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  )
                      .animate(delay: (index * 100).ms)
                      .fade()
                      .scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1F).withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'الترتيب حسب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ['الأحدث', 'الأرخص', 'الأغلى'].map((sort) {
                  final isSelected = currentSort == sort;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _onSortChanged(sort);
                    },
                    child: GlassContainer(
                      borderRadius: 15,
                      backgroundColor: isSelected
                          ? const Color(0xFFEC4899).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEC4899)
                              : Colors.white.withValues(alpha: 0.1)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Text(
                          sort,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    )
                        .animate(target: isSelected ? 1 : 0)
                        .scaleXY(end: 1.05, duration: 200.ms),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('تطبيق',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'Tajawal')),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
