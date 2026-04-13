import 'package:flutter/material.dart';

class Screen52AddNewUser extends StatefulWidget {
  const Screen52AddNewUser({super.key});

  @override
  State<Screen52AddNewUser> createState() => _Screen52AddNewUserState();
}

class _Screen52AddNewUserState extends State<Screen52AddNewUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  DateTime? _selectedDate;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose(); _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF4E6A),
            surface: Color(0xFF1A1D2E),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _submitted = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Patient ${_nameCtrl.text} added successfully!'),
        backgroundColor: const Color(0xFF00C48C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select a date'),
        backgroundColor: const Color(0xFFFF4E6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D2E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C48C).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Color(0xFF00C48C), size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text('Add a New User',
                        style: TextStyle(
                          color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w700, letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 6),
                    Text('Fill in the patient details below',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45), fontSize: 14)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormField(
                      label: 'Patient Name',
                      hint: 'e.g. John Doe',
                      icon: Icons.person_outline_rounded,
                      controller: _nameCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Age',
                      hint: 'e.g. 45',
                      icon: Icons.cake_outlined,
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Age is required';
                        if (int.tryParse(v) == null) return 'Enter a valid age';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Patient ID',
                      hint: 'e.g. PT-007',
                      icon: Icons.badge_outlined,
                      controller: _idCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Patient ID is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    const Text('Session Date',
                        style: TextStyle(
                          color: Color(0xFF1A1D2E),
                          fontWeight: FontWeight.w600, fontSize: 13,
                        )),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10, offset: const Offset(0, 3),
                          )],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFF00C48C), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null
                                  ? 'Select date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? Colors.black.withOpacity(0.35)
                                    : const Color(0xFF1A1D2E),
                                fontSize: 14,
                                fontWeight: _selectedDate == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right,
                                color: Colors.black.withOpacity(0.3), size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Submit
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C48C),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF00C48C).withOpacity(0.35),
                            blurRadius: 18, offset: const Offset(0, 7),
                          )],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _submitted
                                  ? Icons.check_circle
                                  : Icons.person_add_alt_1_rounded,
                              color: Colors.white, size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _submitted ? 'User Added!' : 'Add Patient',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16,
                              ),
                            ),
                          ],
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
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label, required this.hint,
    required this.icon, required this.controller,
    this.keyboardType, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: Color(0xFF1A1D2E),
          fontWeight: FontWeight.w600, fontSize: 13,
        )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
              color: Color(0xFF1A1D2E), fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF00C48C), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00C48C), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF4E6A), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF4E6A), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}