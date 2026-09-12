import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../supabase_client.dart';
import '../theme.dart';

class NewHomeLeaveForm extends StatefulWidget {
  const NewHomeLeaveForm({super.key});

  @override
  State<NewHomeLeaveForm> createState() => _NewHomeLeaveFormState();
}

class _NewHomeLeaveFormState extends State<NewHomeLeaveForm> {
  final _reasonController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _homeContactController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _returnDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      _showMessage('Please enter a reason.');
      return;
    }
    if (!_returnDate.isAfter(_startDate)) {
      _showMessage('Return date must be after leave start date.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await supabase.from('requests').insert({
        'student_id': supabase.auth.currentUser!.id,
        'type': 'home_leave',
        'reason': _reasonController.text.trim(),
        'home_address': _homeAddressController.text.trim(),
        'home_contact': _homeContactController.text.trim(),
        'leave_start_date': DateFormat('yyyy-MM-dd').format(_startDate),
        'expected_return_date': DateFormat('yyyy-MM-dd').format(_returnDate),
        'parent_phone': _parentPhoneController.text.trim(),
      });
      if (mounted) {
        _showMessage('Home leave request submitted.');
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
      appBar: AppBar(title: const Text('New Home Leave')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Reason', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'e.g. Going home for the weekend'),
          ),
          const SizedBox(height: 16),
          const Text('Home Address', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _homeAddressController,
            decoration: const InputDecoration(hintText: 'Address while away'),
          ),
          const SizedBox(height: 16),
          const Text('Contact Number (while away)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _homeContactController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Phone number'),
          ),
          const SizedBox(height: 20),
          const Text('Leave Start Date', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _DateBox(
            label: DateFormat('MMM d, y').format(_startDate),
            onTap: () => _pickDate(true),
          ),
          const SizedBox(height: 20),
          const Text('Expected Return Date', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _DateBox(
            label: DateFormat('MMM d, y').format(_returnDate),
            onTap: () => _pickDate(false),
          ),
          const SizedBox(height: 20),
          const Text("Parent's Phone Number", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _parentPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'For verification'),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Submitting...' : 'Submit Home Leave'),
          ),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateBox({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}