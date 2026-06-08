import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/connectivity/presentation/providers/connectivity_provider.dart';

class Screen0Credentials extends ConsumerStatefulWidget {
  const Screen0Credentials({super.key});

  @override
  ConsumerState<Screen0Credentials> createState() => _Screen0CredentialsState();
}

class _Screen0CredentialsState extends ConsumerState<Screen0Credentials> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  bool _rememberMe = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final connState = ref.read(connectivityProvider);
      _ssidController.text = connState.ssid;
      _passController.text = connState.password;
      setState(() {
        _rememberMe = connState.rememberMe;
      });
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _localError = null;
    });

    final ssid = _ssidController.text.trim();
    final password = _passController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      setState(() {
        _localError = 'SSID and Password fields cannot be empty.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _localError = 'Hotspot password must be at least 8 characters long.';
      });
      return;
    }

    // Save/update credentials in Riverpod
    ref.read(connectivityProvider.notifier).updateCredentials(ssid, password, _rememberMe);

    // Proceed to Turn On BT + Hotspot screen
    context.pushNamed(AppRoutes.connectivity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // ── Header Section ──────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_tethering,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Gait Physio Setup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Enter your Mobile Hotspot details. The wearable band will connect to this network for high-speed sync.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Input Fields Section ─────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hotspot Credentials',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SSID Input
                        TextFormField(
                          controller: _ssidController,
                          decoration: InputDecoration(
                            labelText: 'Hotspot SSID (Network Name)',
                            labelStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                            prefixIcon: const Icon(Icons.wifi, color: AppColors.secondary),
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
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Password Input
                        TextFormField(
                          controller: _passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Hotspot Password',
                            labelStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                            prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Remember Credentials switch
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.secondary,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                            ),
                            Text(
                              'Remember credentials on this phone',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        // Error Banner
                        if (_localError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _localError!,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Continue Button
                        GestureDetector(
                          onTap: _submit,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.navy,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save & Setup Network',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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
        ),
      ),
    );
  }
}
