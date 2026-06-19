import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// Texto con enlaces a términos y privacidad (registro, welcome, etc.).
class LegalLinksText extends StatefulWidget {
  const LegalLinksText({
    super.key,
    required this.prefix,
    this.textAlign = TextAlign.start,
    this.baseStyle,
    this.linkColor,
    this.compact = false,
  });

  final String prefix;
  final TextAlign textAlign;
  final TextStyle? baseStyle;
  final Color? linkColor;
  final bool compact;

  @override
  State<LegalLinksText> createState() => _LegalLinksTextState();
}

class _LegalLinksTextState extends State<LegalLinksText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer();
    _privacyRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _termsRecognizer.onTap = () => context.push('/legal/terms');
    _privacyRecognizer.onTap = () => context.push('/legal/privacy');

    final theme = Theme.of(context);
    final style = widget.baseStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        );
    final links = widget.linkColor ?? AppColors.primaryDark;

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: widget.prefix),
          TextSpan(
            text: 'Términos y condiciones',
            style: style?.copyWith(
              color: links,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' y la '),
          TextSpan(
            text: 'Política de privacidad',
            style: style?.copyWith(
              color: links,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: _privacyRecognizer,
          ),
          TextSpan(text: widget.compact ? '.' : ' de tinDog.'),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}
