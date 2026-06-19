import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/password_strength.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
  });

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.none) return const SizedBox.shrink();

    final activeSegments = switch (strength) {
      PasswordStrength.weak => 1,
      PasswordStrength.medium => 2,
      PasswordStrength.strong => 3,
      PasswordStrength.none => 0,
    };

    final activeColor = switch (strength) {
      PasswordStrength.weak => const Color(0xFFD64545),
      PasswordStrength.medium => const Color(0xFFD4A017),
      PasswordStrength.strong => AppColors.accent,
      PasswordStrength.none => AppColors.border,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index < activeSegments;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            'Fortaleza: ${strength.label}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
