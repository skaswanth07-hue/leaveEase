import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../supabase_client.dart';
import '../theme.dart';
import 'student_history_screen.dart';
import 'records_view.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({super.key});

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _overdue = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _checkOverdue();
    _sub = supabase.from('requests').stream(primaryKey: ['id']).listen((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final pending = await supabase
        .from('requests')
        .select('*, profiles:student_id(name, register_no, year_of_study, room_no, flagged)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    final overdue = await supabase
        .from('requests')
        .select('*, profiles:student_id(name, register_no, room_no)')
        .eq('overdue', true)
        .isFilter('actual_return_time', null);

    if (mounted) {
      setState(() {
        _pending = List<Map<String, dynamic>>.from(pending);
        _overdue = List<Map<String, dynamic>>.from(overdue);
        _loading = false;
      });
    }
  }

  Future<void> _checkOverdue() async {
    final now = DateTime.now().toIso8601String();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await supabase
        .from('requests')
        .update({'overdue': true})
        .eq('type', 'outpass')
        .eq('status', 'approved')
        .isFilter('actual_return_time', null)
        .lt('expected_return_time', now)
        .eq('overdue', false);

    await supabase
        .from('requests')
        .update({'overdue': true})
        .eq('type', 'home_leave')
        .eq('status', 'approved')
        .isFilter('actual_return_time', null)
        .lt('expected_return_date', today)
        .eq('overdue', false);

    _load();
  }

  Future<void> _review(String requestId, String status) async {
    await supabase.from('requests').update({
      'status': status,
      'reviewed_by': supabase.auth.currentUser!.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
    _load();
  }

  Future<void> _callParent(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warden Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle(title: 'Pending Requests'),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const RecordsView())),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('Records'),
                ),
              ],
            ),
            if (_overdue.isNotEmpty) _OverdueBanner(items: _overdue, onDismiss: (id) async {
              await supabase.from('requests').update({'overdue_dismissed': true}).eq('id', id);
              _load();
            }, onTapStudent: (studentId, name) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StudentHistoryScreen(studentId: studentId, studentName: name)));
            }),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_pending.isEmpty)
              const EmptyState(icon: Icons.check_circle_outline_rounded, message: 'No pending requests')
            else
              ..._pending.map((r) => _PendingCard(
                    request: r,
                    onApprove: () => _review(r['id'], 'approved'),
                    onReject: () => _review(r['id'], 'rejected'),
                    onCallParent: _callParent,
                    onTapStudent: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => StudentHistoryScreen(
                                studentId: r['student_id'],
                                studentName: r['profiles']?['name'] ?? 'Unknown'))),
                  )),
          ],
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(String) onDismiss;
  final Function(String, String) onTapStudent;

  const _OverdueBanner({required this.items, required this.onDismiss, required this.onTapStudent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠ ${items.length} Overdue',
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...items.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTapStudent(r['student_id'], r['profiles']?['name'] ?? 'Unknown'),
                        child: Text(
                          '${r['profiles']?['name'] ?? 'Unknown'} · Reg. ${r['profiles']?['register_no'] ?? '-'}',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onDismiss(r['id']),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final Function(String) onCallParent;
  final VoidCallback onTapStudent;

  const _PendingCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onCallParent,
    required this.onTapStudent,
  });

  @override
  Widget build(BuildContext context) {
    final profile = request['profiles'] as Map<String, dynamic>?;
    final isOutpass = request['type'] == 'outpass';
    final parentPhone = request['parent_phone'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTapStudent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isOutpass ? 'Outpass' : 'Home Leave',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (profile?['flagged'] == true)
                        const Text('⚠ Flagged',
                            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('${profile?['name'] ?? 'Unknown'} · Reg. ${profile?['register_no'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Year ${profile?['year_of_study'] ?? '-'} · Room ${profile?['room_no'] ?? '-'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(request['reason'] ?? ''),
                  const SizedBox(height: 6),
                  if (isOutpass)
                    Text(
                      'Out: ${_fmt(request['expected_out_time'])}  →  Return: ${_fmt(request['expected_return_time'])}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    )
                  else ...[
                    Text('${request['leave_start_date']} → ${request['expected_return_date']}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (request['home_address'] != null && request['home_address'].toString().isNotEmpty)
                      Text('Address: ${request['home_address']}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (parentPhone != null && parentPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: InkWell(
                  onTap: () => onCallParent(parentPhone),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Call Parent: $parentPhone',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '-';
    return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso).toLocal());
  }
}