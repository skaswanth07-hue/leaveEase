import 'package:flutter/material.dart';

import '../supabase_client.dart';

class StudentRequests extends StatefulWidget {
  const StudentRequests({super.key});

  @override
  State<StudentRequests> createState() => _StudentRequestsState();
}

class _StudentRequestsState extends State<StudentRequests> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Not authenticated';
      final data = await supabase
          .from('requests')
          .select()
          .eq('student_id', user.id)
          .order('created_at', ascending: false);
      setState(() => _requests = (data as List<dynamic>? ?? <dynamic>[]));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _colorForStatus(String s) {
    switch (s) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _requests.length,
                itemBuilder: (context, i) {
                  final r = _requests[i];
                  final type = r['type'] ?? 'request';
                  final status = r['status'] ?? 'pending';
                  final start = r['start_date'] ?? '';
                  final end = r['end_date'] ?? '';
                  return Card(
                    child: ListTile(
                      title: Text('$type'.replaceAll('_', ' ').toUpperCase()),
                      subtitle: Text('$start → $end\n${r['reason'] ?? ''}'),
                      isThreeLine: true,
                      trailing: Chip(
                        label: Text(status),
                        backgroundColor: _colorForStatus(status),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
