import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/router/app_router.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';

class Screen53SessionConfirmation extends ConsumerWidget {
  final UserModel user;

  const Screen53SessionConfirmation({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    const SizedBox(height: 20),
                    const Text(
                      'Session Setup',
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

          // ── Confirmation Details ──────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Patient',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age: ${user.age}  ·  ID: ${user.id}',
                          style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem('1', 'Confirm the wearable device is paired and online.'),
                  const SizedBox(height: 10),
                  _buildInstructionItem('2', 'Affix the sensor band securely on the patient\'s left ankle.'),
                  const SizedBox(height: 10),
                  _buildInstructionItem('3', 'Ask the patient to walk in a straight line at their natural pace once recording starts.'),
                  const SizedBox(height: 10),
                  _buildInstructionItem('4', 'Click "Start Recording" to issue the trigger command to the wearable sensor.'),

                  const Spacer(),

                  GestureDetector(
                    onTap: () {
                      context.pushNamed(
                        AppRoutes.liveSession,
                        extra: {'user': user},
                      );
                    },
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Start Recording',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.2,
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
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
