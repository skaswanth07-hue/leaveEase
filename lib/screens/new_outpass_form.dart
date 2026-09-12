import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';
import '../theme.dart';

class NewOutpassForm extends StatefulWidget {
  const NewOutpassForm({super.key});

  @override
  State<NewOutpassForm> createState() => _NewOutpassFormState();
}

class _NewOutpassFormState extends State<NewOutpassForm> {
  final _reasonController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  DateTime _outDate = DateTime.now();
  TimeOfDay _outTime = TimeOfDay.now();
  DateTime _returnDate = DateTime.now();
  TimeOfDay _returnTime = TimeOfDay.now();

  bool _submitting = false;

  Future<void> _pickDate(bool isOut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isOut ? _outDate : _returnDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isOut) {
          _outDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isOut) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOut ? _outTime : _returnTime,
    );
    if (picked != null) {
      setState(() {
        if (isOut) {
          _outTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      _showMessage('Please enter a reason.');
      return;
    }

    final finalOut = _combine(_outDate, _outTime);
    final finalReturn = _combine(_returnDate, _returnTime);

    if (finalReturn.isBefore(finalOut) || finalReturn.isAtSameMomentAs(finalOut)) {
      _showMessage('Return time must be after out time.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await supabase.from('requests').insert({
        'student_id': supabase.auth.currentUser!.id,
        'type': 'outpass',
        'reason': _reasonController.text.trim(),
        'expected_out_time': finalOut.toIso8601String(),
        'expected_return_time': finalReturn.toIso8601String(),
        'parent_phone': _parentPhoneController.text.trim(),
      });
      if (mounted) {
        _showMessage('Outpass request submitted.');
        Navigator.pop(context);
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Outpass')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Reason', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'e.g. Going to the market'),
          ),
          const SizedBox(height: 20),
          const Text('Expected Out', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateTimeBox(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('MMM d, y').format(_outDate),
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeBox(
                  icon: Icons.access_time_rounded,
                  label: _outTime.format(context),
                  onTap: () => _pickTime(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Expected Return', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateTimeBox(
                  icon: Icons.calendar_today_rounded,
                  label: DateFormat('MMM d, y').format(_returnDate),
                  onTap: () => _pickDate(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTimeBox(
                  icon: Icons.access_time_rounded,
                  label: _returnTime.format(context),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Parent's Phone Number", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _parentPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'For warden verification if needed'),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Submit Outpass'),
          ),
        ],
      ),
    );
  }
}

class _DateTimeBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeBox({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}