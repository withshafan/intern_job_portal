import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../theme/app_theme.dart';


class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  DateTime? _selectedDeadline;
  String? _assignedToId;
  String? _assignedToName;
  List<Map<String, dynamic>> _interns = [];
  bool _loading = false;
  bool _loadingInterns = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<app_auth.AuthProvider>();
    if (auth.isAdmin) _loadInterns();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInterns() async {
    setState(() => _loadingInterns = true);
    final users = await _userService.getAllUsers();
    setState(() {
      _interns = users.where((u) => u['role'] == 'intern').toList();
      _loadingInterns = false;
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryIndigo),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      _showError('Please select a deadline');
      return;
    }
    final auth = context.read<app_auth.AuthProvider>();
    if (auth.isAdmin && _assignedToId == null) {
      _showError('Please select an intern to assign this task');
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _taskService.createTask(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        deadline: _selectedDeadline!,
        assignedTo: auth.isAdmin ? _assignedToId! : uid,
        assignedBy: uid,
        assignedToName: auth.isAdmin ? _assignedToName : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task created successfully! ✓'),
            backgroundColor: AppTheme.statusCompleted,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to create task: $e');
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<app_auth.AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Assign Task' : 'New Task'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Task Details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined, size: 20),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Deadline'),
              const SizedBox(height: 12),
              // Date picker
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E2533)
                        : const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDeadline != null
                          ? AppTheme.primaryIndigo
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: _selectedDeadline != null
                            ? AppTheme.primaryIndigo
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDeadline == null
                            ? 'Select deadline date'
                            : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDeadline == null
                              ? Colors.grey.shade500
                              : null,
                          fontWeight: _selectedDeadline != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 24),
                _sectionTitle('Assign To'),
                const SizedBox(height: 12),
                _loadingInterns
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        initialValue: _assignedToId,
                        decoration: const InputDecoration(
                          labelText: 'Select Intern',
                          prefixIcon:
                              Icon(Icons.person_outline, size: 20),
                        ),
                        items: _interns
                            .map((u) => DropdownMenuItem<String>(
                                  value: u['id'],
                                  child: Text(
                                      u['name'] ?? u['email'] ?? 'Unknown'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _assignedToId = val;
                            _assignedToName = _interns.firstWhere(
                                (u) => u['id'] == val)['name'];
                          });
                        },
                        validator: isAdmin
                            ? (v) => v == null ? 'Please select an intern' : null
                            : null,
                      ),
              ],
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(isAdmin ? 'Assign Task' : 'Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppTheme.primaryIndigo,
        ),
      );
}
