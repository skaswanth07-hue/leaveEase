import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';
import '../theme.dart';

class ActivePassScreen extends StatefulWidget {
  final String requestId;
  const ActivePassScreen({super.key, required this.requestId});

  @override
  State<ActivePassScreen> createState() => _ActivePassScreenState();
}

class _ActivePassScreenState extends State<ActivePassScreen> {
  Map<String, dynamic>? _request;
  bool _loading = true;
  bool _updating = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = supabase
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('id', widget.requestId)
        .listen((data) {
      if (data.isNotEmpty) {
        setState(() {
          _request = data.first;
          _loading = false;
        });
      }
    });
  }

  Future<void> _load() async {
    final data = await supabase.from('requests').select().eq('id', widget.requestId).single();
    setState(() {
      _request = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _markOut() async {
    setState(() => _updating = true);
    try {
      await supabase
          .from('requests')
          .update({'actual_out_time': DateTime.now().toIso8601String()})
          .eq('id', widget.requestId);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _markBack() async {
    setState(() => _updating = true);
    try {
      await supabase.from('requests').update({
        'actual_return_time': DateTime.now().toIso8601String(),
        'overdue': false,
      }).eq('id', widget.requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back! Your return has been logged.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _request == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final r = _request!;
    final isOutpass = r['type'] == 'outpass';
    final alreadyOut = r['actual_out_time'] != null;
    final alreadyBack = r['actual_return_time'] != null;
    final overdue = r['overdue'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Active Pass')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isOutpass ? 'Outpass' : 'Home Leave',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(r['reason'] ?? '', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 12),
                  if (isOutpass)
                    Text(
                      'Expected out: ${_fmt(r['expected_out_time'])}\nExpected return: ${_fmt(r['expected_return_time'])}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    )
                  else
                    Text(
                      '${r['leave_start_date']} → ${r['expected_return_date']}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  if (alreadyOut) ...[
                    const SizedBox(height: 10),
                    Text('✓ Marked out at ${_fmt(r['actual_out_time'])}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                  if (alreadyBack) ...[
                    const SizedBox(height: 6),
                    Text('✓ Marked back at ${_fmt(r['actual_return_time'])}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                  if (overdue) ...[
                    const SizedBox(height: 10),
                    const Text('⚠ Overdue', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!alreadyOut)
              ElevatedButton.icon(
                onPressed: _updating ? null : _markOut,
                icon: const Icon(Icons.logout_rounded),
                label: Text(_updating ? 'Updating...' : "I'm Out"),
              ),
            if (alreadyOut && !alreadyBack)
              ElevatedButton.icon(
                onPressed: _updating ? null : _markBack,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                icon: const Icon(Icons.login_rounded),
                label: Text(_updating ? 'Updating...' : "I'm Back"),
              ),
            if (alreadyOut && alreadyBack)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('This pass has been completed.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '-';
    return DateFormat('MMM d, y · h:mm a').format(DateTime.parse(iso).toLocal());
  }
}