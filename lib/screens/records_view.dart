import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';
import '../theme.dart';

class RecordsView extends StatefulWidget {
  const RecordsView({super.key});

  @override
  State<RecordsView> createState() => _RecordsViewState();
}

class _RecordsViewState extends State<RecordsView> {
  final _nameController = TextEditingController();
  String? _type;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    var query = supabase.from('requests').select('*, profiles:student_id(name)');

    if (_type != null) {
      query = query.eq('type', _type!);
    }

    final data = await query.order('created_at', ascending: false);
    var results = List<Map<String, dynamic>>.from(data);

    if (_nameController.text.trim().isNotEmpty) {
      final search = _nameController.text.trim().toLowerCase();
      results = results.where((r) {
        final name = (r['profiles']?['name'] ?? '').toString().toLowerCase();
        return name.contains(search);
      }).toList();
    }

    setState(() {
      _records = results;
      _loading = false;
    });
  }

  void _clear() {
    _nameController.clear();
    setState(() => _type = null);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Filter Records', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Student name'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _TypeChip(label: 'All', selected: _type == null, onTap: () => setState(() => _type = null)),
              _TypeChip(
                  label: 'Outpass',
                  selected: _type == 'outpass',
                  onTap: () => setState(() => _type = 'outpass')),
              _TypeChip(
                  label: 'Home Leave',
                  selected: _type == 'home_leave',
                  onTap: () => setState(() => _type = 'home_leave')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(onPressed: _search, child: const Text('Apply Filters')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(onPressed: _clear, child: const Text('Clear')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(title: 'Results (${_records.length})'),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_records.isEmpty)
            const EmptyState(icon: Icons.search_off_rounded, message: 'No matching records')
          else
            ..._records.map((r) => _RecordCard(record: r)),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isOutpass = record['type'] == 'outpass';
    final createdAt = DateTime.parse(record['created_at']).toLocal();
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
                StatusChip(status: record['status']),
              ],
            ),
            const SizedBox(height: 6),
            Text(record['profiles']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(record['reason'] ?? ''),
            const SizedBox(height: 6),
            Text(DateFormat('MMM d, y · h:mm a').format(createdAt),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}