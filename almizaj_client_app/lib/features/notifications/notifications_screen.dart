import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:almizaj_client_app/core/network/api_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res =
          await http.get(Uri.parse('${ApiConfig.baseUrl}/api/notifications'));
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data['ok'] == true) {
        setState(() {
          _notifs = data['notifications'];
          _unread = data['unread'];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _readAll() async {
    try {
      await http
          .post(Uri.parse('${ApiConfig.baseUrl}/api/notifications/read_all'));
      setState(() {
        _unread = 0;
        for (var n in _notifs) {
          n['is_read'] = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _readOne(int id, int index) async {
    try {
      await http
          .post(Uri.parse('${ApiConfig.baseUrl}/api/notifications/read/$id'));
      setState(() {
        _notifs[index]['is_read'] = true;
        if (_unread > 0) _unread--;
      });
    } catch (_) {}
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'danger':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'danger':
        return Icons.error_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('الإشعارات',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontFamily: 'Tajawal')),
            if (_unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$_unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ]),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_unread > 0)
              TextButton(
                onPressed: _readAll,
                child: const Text('قراءة الكل',
                    style: TextStyle(
                        color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
            : _notifs.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _fetch,
                    color: const Color(0xFF8B5CF6),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifs.length,
                      itemBuilder: (ctx, i) {
                        final n = _notifs[i];
                        final color = _typeColor(n['type'] ?? 'info');
                        final isRead = n['is_read'] == true;
                        return GestureDetector(
                          onTap: () => _readOne(n['id'], i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.white
                                  : color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead
                                    ? const Color(0xFFE2E8F0)
                                    : color.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        shape: BoxShape.circle),
                                    child: Icon(_typeIcon(n['type'] ?? 'info'),
                                        color: color, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(n['title'] ?? '',
                                                  style: TextStyle(
                                                    fontWeight: isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.w900,
                                                    fontSize: 14,
                                                    color:
                                                        const Color(0xFF1E293B),
                                                  )),
                                            ),
                                            if (!isRead)
                                              Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(n['message'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B),
                                                height: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(n['created_at'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('لا توجد إشعارات حالياً',
              style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('سنُعلمك بأحدث العروض والطلبات',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
        ]),
      );
}
