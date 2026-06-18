import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

/// Logo oficial multicolor de Google (asset local, sin parpadeos).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  static const _assetPath = 'assets/branding/google_logo.svg';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'Google',
      // Sin placeholder: el spinner hacía parecer que el logo "cambiaba".
      errorBuilder: (_, _, _) => Icon(
        Icons.g_mobiledata_rounded,
        size: size + 4,
        color: AppColors.textPrimary,
      ),
    );
  }
}
