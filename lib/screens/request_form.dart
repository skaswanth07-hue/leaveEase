import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../supabase_client.dart';

enum RequestType { hostelPass, outpass }

class RequestForm extends StatefulWidget {
  final RequestType type;
  const RequestForm({super.key, required this.type});

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _loading = false;

  String _format(DateTime d) => DateFormat.yMMMd().format(d);

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isStart)
        _startDate = picked;
      else
        _endDate = picked;
    });
  }

  Future<void> _submit() async {
    if (widget.type == RequestType.hostelPass &&
        (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick start and end dates')));
      return;
    }
    if (widget.type == RequestType.outpass && _startDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick the outing date')));
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Provide a reason')));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'Not authenticated';

      final now = DateTime.now().toIso8601String();
      final start =
          (widget.type == RequestType.outpass ? _startDate : _startDate)!
              .toIso8601String();
      final end = (widget.type == RequestType.outpass ? _startDate : _endDate)!
          .toIso8601String();

      await supabase.from('requests').insert({
        'student_id': user.id,
        'type': widget.type == RequestType.hostelPass
            ? 'hostel_pass'
            : 'outpass',
        'start_date': start,
        'end_date': end,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'created_at': now,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request submitted')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHostel = widget.type == RequestType.hostelPass;
    return Scaffold(
      appBar: AppBar(
        title: Text(isHostel ? 'Hostel Pass Request' : 'Outpass Request'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ListTile(
              title: Text(isHostel ? 'Long leave' : 'Single day outing'),
              subtitle: Text(
                isHostel ? 'Pick start and end dates' : 'Pick outing date',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(
                      _startDate == null ? 'Pick start' : _format(_startDate!),
                    ),
                  ),
                ),
                if (isHostel) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text(
                        _endDate == null ? 'Pick end' : _format(_endDate!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason for leave/outing',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Submitting...' : 'Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
