import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';
import '../theme.dart';

class StudentHistoryScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const StudentHistoryScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  List<Map<String, dynamic>> _requests = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _flagged = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await supabase.from('profiles').select().eq('id', widget.studentId).single();
    final requests = await supabase
        .from('requests')
        .select()
        .eq('student_id', widget.studentId)
        .order('created_at', ascending: false);

    setState(() {
      _profile = profile;
      _flagged = profile['flagged'] == true;
      _requests = List<Map<String, dynamic>>.from(requests);
      _loading = false;
    });
  }

  Future<void> _toggleFlag(bool value) async {
    setState(() => _flagged = value);
    try {
      await supabase.from('profiles').update({'flagged': value}).eq('id', widget.studentId);
    } catch (e) {
      setState(() => _flagged = !value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.studentName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Reg. ${_profile?['register_no'] ?? '-'} · Year ${_profile?['year_of_study'] ?? '-'} · Room ${_profile?['room_no'] ?? '-'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('Flag as frequent late-returner')),
                          Switch(value: _flagged, onChanged: _toggleFlag),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle(title: 'Request History'),
                if (_requests.isEmpty)
                  const EmptyState(icon: Icons.history_rounded, message: 'No past requests')
                else
                  ..._requests.map((r) => _HistoryCard(request: r)),
              ],
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _HistoryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isOutpass = request['type'] == 'outpass';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isOutpass ? 'Outpass' : 'Home Leave',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                StatusChip(status: request['status']),
              ],
            ),
            const SizedBox(height: 8),
            Text(request['reason'] ?? ''),
            const SizedBox(height: 6),
            if (isOutpass)
              Text(
                'Out: ${_fmt(request['expected_out_time'])}  →  Return: ${_fmt(request['expected_return_time'])}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              )
            else
              Text('${request['leave_start_date']} → ${request['expected_return_date']}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (request['actual_out_time'] != null)
              Text('Actually out: ${_fmt(request['actual_out_time'])}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (request['actual_return_time'] != null)
              Text('Actually back: ${_fmt(request['actual_return_time'])}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (request['overdue'] == true)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('⚠ Was overdue',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12)),
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