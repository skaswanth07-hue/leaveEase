import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';
import '../theme.dart';
import 'new_outpass_form.dart';
import 'new_home_leave_form.dart';
import 'active_pass_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = supabase
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('student_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .listen((data) {
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await supabase
        .from('requests')
        .select()
        .eq('student_id', supabase.auth.currentUser!.id)
        .order('created_at', ascending: false);
    setState(() {
      _requests = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeaveEase'),
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
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.directions_walk_rounded,
                    label: 'New Outpass',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NewOutpassForm())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.home_rounded,
                    label: 'New Home Leave',
                    color: AppColors.primaryDark,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NewHomeLeaveForm())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'My Requests'),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_requests.isEmpty)
              const EmptyState(icon: Icons.inbox_rounded, message: 'No requests yet')
            else
              ..._requests.map((r) => _RequestCard(request: r)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isOutpass = request['type'] == 'outpass';
    final status = request['status'] as String;
    final createdAt = DateTime.parse(request['created_at']).toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: InkWell(
          onTap: status == 'approved'
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActivePassScreen(requestId: request['id']),
                  ))
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOutpass ? Icons.directions_walk_rounded : Icons.home_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOutpass ? 'Outpass' : 'Home Leave',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                  StatusChip(status: status),
                ],
              ),
              if (status == 'approved') ...[
                const SizedBox(height: 6),
                const Text('Tap to log in/out →',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 8),
              Text(request['reason'] ?? '', style: const TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d, y · h:mm a').format(createdAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}