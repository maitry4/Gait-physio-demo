import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/features/user_management/presentation/providers/user_provider.dart';

class Screen52AddNewUser extends ConsumerStatefulWidget {
  const Screen52AddNewUser({super.key});

  @override
  ConsumerState<Screen52AddNewUser> createState() => _Screen52AddNewUserState();
}

class _Screen52AddNewUserState extends ConsumerState<Screen52AddNewUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _idController = TextEditingController();
  final _dateController = TextEditingController();
  bool _simulateDeviceFailure = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _idController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final id = _idController.text.trim();

    final success = await ref.read(userProvider.notifier).registerNewUser(
          name: name,
          age: age,
          id: id,
          simulateDeviceFailure: _simulateDeviceFailure,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered $name on wearable and local database!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      // Display failure modal with retry option
      _showFailureDialog(name, age, id);
    }
  }

  void _showFailureDialog(String name, int age, String id) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Wearable Write Failed'),
            ],
          ),
          content: const Text(
            'The mobile app could not sync user metadata to the wearable band. Please check your Bluetooth connection and tap retry.',
          ),
          actions: [
            TextButton(
              onPressed: () => dialogContext.pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.black.withOpacity(0.5))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                dialogContext.pop();
                _submit();
              },
              child: const Text('Retry Write', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                          ),
                        ),
                        // Error Sim Toggle
                        Row(
                          children: [
                            const Icon(Icons.bug_report, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            const Text('Simulate Error', style: TextStyle(color: Colors.white, fontSize: 10)),
                            Checkbox(
                              value: _simulateDeviceFailure,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _simulateDeviceFailure = val ?? false;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Registration Form',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form Inputs ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Details',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                      decoration: _inputDecoration('Patient Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 14),

                    // Age
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter an age';
                        if (int.tryParse(val.trim()) == null) return 'Please enter a valid number';
                        return null;
                      },
                      decoration: _inputDecoration('Age', Icons.calendar_today_outlined),
                    ),
                    const SizedBox(height: 14),

                    // Patient ID
                    TextFormField(
                      controller: _idController,
                      decoration: _inputDecoration('Patient ID (Optional, Autogenerated if blank)', Icons.fingerprint_outlined),
                    ),
                    const SizedBox(height: 14),

                    // Date
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: _inputDecoration('Date Registered', Icons.date_range),
                    ),
                    const SizedBox(height: 36),

                    // Add Button
                    GestureDetector(
                      onTap: userState.isLoading ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: userState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Add Patient to Device & Local DB',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.secondary, width: 2),
      ),
    );
  }
}
