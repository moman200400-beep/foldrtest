import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  int _defaultIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_addresses') ?? '[]';
    final di = prefs.getInt('default_address') ?? 0;
    try {
      final list = List<Map<String, dynamic>>.from(json.decode(raw));
      if (mounted) {
        setState(() {
          _addresses = list;
          _defaultIndex = di;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_addresses', json.encode(_addresses));
    await prefs.setInt('default_address', _defaultIndex);
  }

  void _addOrEditAddress({int? editIndex}) {
    final isEdit = editIndex != null;
    final ex = isEdit ? _addresses[editIndex] : <String, dynamic>{};
    final lCtrl = TextEditingController(text: ex['label'] ?? '');
    final cCtrl = TextEditingController(text: ex['city'] ?? '');
    final dCtrl = TextEditingController(text: ex['district'] ?? '');
    final sCtrl = TextEditingController(text: ex['street'] ?? '');
    final bCtrl = TextEditingController(text: ex['building'] ?? '');
    final nCtrl = TextEditingController(text: ex['notes'] ?? '');
    String selType = ex['type'] ?? 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 18),
                  Text(isEdit ? 'تعديل العنوان' : 'إضافة عنوان جديد',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Tajawal',
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 20),
                  const Text('نوع العنوان',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _typeChip('home', 'المنزل', Icons.home_outlined, selType,
                        (v) => setS(() => selType = v)),
                    const SizedBox(width: 8),
                    _typeChip('work', 'العمل', Icons.work_outline, selType,
                        (v) => setS(() => selType = v)),
                    const SizedBox(width: 8),
                    _typeChip('other', 'اخرى', Icons.location_on_outlined,
                        selType, (v) => setS(() => selType = v)),
                  ]),
                  const SizedBox(height: 14),
                  _field(
                      lCtrl, 'اسم العنوان (مثل: بيت امي)', Icons.label_outline),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: _field(
                            cCtrl, 'المدينة', Icons.location_city_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(dCtrl, 'الحي', Icons.map_outlined)),
                  ]),
                  const SizedBox(height: 10),
                  _field(sCtrl, 'الشارع', Icons.edit_road_outlined),
                  const SizedBox(height: 10),
                  _field(bCtrl, 'رقم المبنى / الشقة', Icons.apartment_outlined),
                  const SizedBox(height: 10),
                  _field(
                      nCtrl, 'ملاحظات اضافية (اختياري)', Icons.notes_outlined,
                      maxLines: 2),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (cCtrl.text.trim().isEmpty ||
                            sCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('يرجى ادخال المدينة والشارع'),
                                  backgroundColor: Colors.red));
                          return;
                        }
                        final addr = {
                          'type': selType,
                          'label': lCtrl.text.trim().isNotEmpty
                              ? lCtrl.text.trim()
                              : (selType == 'home'
                                  ? 'المنزل'
                                  : selType == 'work'
                                      ? 'العمل'
                                      : 'عنوان جديد'),
                          'city': cCtrl.text.trim(),
                          'district': dCtrl.text.trim(),
                          'street': sCtrl.text.trim(),
                          'building': bCtrl.text.trim(),
                          'notes': nCtrl.text.trim(),
                        };
                        setState(() {
                          if (isEdit) {
                            _addresses[editIndex] = addr;
                          } else {
                            _addresses.add(addr);
                          }
                        });
                        _saveAddresses();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              isEdit ? 'تم تعديل العنوان' : 'تم اضافة العنوان'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                      child: Text(isEdit ? 'حفظ التعديلات' : 'اضافة العنوان',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal')),
                    ),
                  ),
                  const SizedBox(height: 8),
                ])),
          ),
        ),
      ),
    );
  }

  void _deleteAddress(int index) {
    showDialog(
        context: context,
        builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text('حذف العنوان',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('هل انت متأكد من حذف هذا العنوان؟'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('الغاء',
                          style: TextStyle(color: Color(0xFF94A3B8)))),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _addresses.removeAt(index);
                        if (_defaultIndex >= _addresses.length) {
                          _defaultIndex = 0;
                        }
                      });
                      _saveAddresses();
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('عناوين التوصيل',
              style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal',
                  fontSize: 20)),
          actions: [
            TextButton.icon(
              onPressed: _addOrEditAddress,
              icon: const Icon(Icons.add, color: Color(0xFF8B5CF6), size: 18),
              label: const Text('اضافة',
                  style: TextStyle(
                      color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: _addresses.isEmpty
            ? _emptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final addr = _addresses[index];
                  final isDefault = index == _defaultIndex;
                  final type = addr['type'] ?? 'other';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isDefault
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFFE2E8F0),
                          width: isDefault ? 2 : 1),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: _typeColor(type)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(_typeIcon(type),
                                        color: _typeColor(type), size: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Row(children: [
                                        Text(addr['label'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF1E293B))),
                                        if (isDefault) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF8B5CF6),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: const Text('افتراضي',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold))),
                                        ],
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(_buildAddressText(addr),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              height: 1.5)),
                                    ])),
                              ]),
                              if (addr['notes'] != null &&
                                  addr['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3CD),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(children: [
                                      const Icon(Icons.notes,
                                          size: 13, color: Color(0xFF856404)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(addr['notes'],
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF856404)))),
                                    ])),
                              ],
                              const SizedBox(height: 12),
                              Row(children: [
                                if (!isDefault)
                                  Expanded(
                                      child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() => _defaultIndex = index);
                                      _saveAddresses();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'تم تعيين العنوان الافتراضي'),
                                              backgroundColor:
                                                  Color(0xFF8B5CF6),
                                              behavior:
                                                  SnackBarBehavior.floating));
                                    },
                                    icon: const Icon(Icons.check_circle_outline,
                                        size: 15),
                                    label: const Text('تعيين افتراضي',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF8B5CF6),
                                        side: const BorderSide(
                                            color: Color(0xFF8B5CF6)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8)),
                                  ))
                                else
                                  const Expanded(child: SizedBox()),
                                const SizedBox(width: 8),
                                IconButton(
                                    onPressed: () =>
                                        _addOrEditAddress(editIndex: index),
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Color(0xFF3B82F6), size: 20),
                                    style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                                const SizedBox(width: 8),
                                IconButton(
                                    onPressed: () => _deleteAddress(index),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Color(0xFFEF4444), size: 20),
                                    style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)))),
                              ]),
                            ])),
                  );
                },
              ),
        floatingActionButton: _addresses.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: _addOrEditAddress,
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('عنوان جديد',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  String _buildAddressText(Map<String, dynamic> addr) {
    final parts = <String>[];
    if (addr['city']?.toString().isNotEmpty == true) parts.add(addr['city']);
    if (addr['district']?.toString().isNotEmpty == true) {
      parts.add('حي ${addr['district']}');
    }
    if (addr['street']?.toString().isNotEmpty == true) {
      parts.add('شارع ${addr['street']}');
    }
    if (addr['building']?.toString().isNotEmpty == true) {
      parts.add('مبنى ${addr['building']}');
    }
    return parts.join('، ');
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'home':
        return const Color(0xFF10B981);
      case 'work':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  Widget _typeChip(String value, String label, IconData icon, String selected,
      Function(String) onTap) {
    final isSel = selected == value;
    return Expanded(
        child: GestureDetector(
            onTap: () => onTap(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: isSel
                      ? _typeColor(value).withValues(alpha: 0.12)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          isSel ? _typeColor(value) : const Color(0xFFE2E8F0),
                      width: isSel ? 1.5 : 1)),
              child: Column(children: [
                Icon(icon,
                    color: isSel ? _typeColor(value) : const Color(0xFF94A3B8),
                    size: 20),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSel
                            ? _typeColor(value)
                            : const Color(0xFF94A3B8))),
              ]),
            )));
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, fontFamily: 'Tajawal'),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12))),
    );
  }

  Widget _emptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                shape: BoxShape.circle),
            child: const Icon(Icons.location_off_outlined,
                size: 55, color: Color(0xFF8B5CF6))),
        const SizedBox(height: 22),
        const Text('لا توجد عناوين محفوظة',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                fontFamily: 'Tajawal')),
        const SizedBox(height: 8),
        const Text('اضف عنوانك لتسريع عملية التوصيل',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        const SizedBox(height: 30),
        ElevatedButton.icon(
            onPressed: _addOrEditAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('اضافة عنوان الان',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0)),
      ]));
}
