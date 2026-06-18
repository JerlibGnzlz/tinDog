import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WelcomeAuthButton extends StatelessWidget {
  const WelcomeAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(child: icon),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
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
