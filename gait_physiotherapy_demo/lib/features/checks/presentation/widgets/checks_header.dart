class ChecksHeader extends StatelessWidget {
  final bool isComplete;

  const ChecksHeader({
    super.key,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
     Container(
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
                    const SizedBox(height: 24),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: checkState.isComplete 
                            ? AppColors.success.withOpacity(0.4)
                            : AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        checkState.isComplete ? Icons.check_circle : Icons.shield_outlined,
                        size: 60,
                        color: checkState.isComplete ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Startup Checks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Validating device security, local models, and hardware capabilities.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
  }
}