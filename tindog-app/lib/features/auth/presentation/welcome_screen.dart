import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../shared/widgets/tindog_gradient_background.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_tagline.dart';
import '../../../shared/widgets/google_logo.dart';
import '../../../shared/widgets/tindog_text_button.dart';
import '../../../shared/widgets/welcome_auth_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _cookiesRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
    _privacyRecognizer = TapGestureRecognizer();
    _cookiesRecognizer = TapGestureRecognizer();
    _termsRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    _cookiesRecognizer.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  void _openPrivacy() => context.push('/legal/privacy');

  void _openCookies() => context.push('/legal/cookies');

  void _openTerms() => context.push('/legal/terms');

  void _showComingSoon() {
    showTindogInfoSnackBar(context, 'Próximamente disponible');
  }

  void _openForgotPassword() => context.push('/forgot-password');

  TextStyle? _legalStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          height: 1.45,
        );
  }

  Widget _brandBlock({required double logoSize, double? titleSize}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedAppLogo(size: logoSize)
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 550.ms,
              curve: Curves.easeOutCubic,
            )
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              duration: 650.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 20),
        Text(
          'tinDog',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: titleSize,
              ),
        )
            .animate()
            .fadeIn(delay: 100.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms),
        const SizedBox(height: 10),
        AppTagline(compact: titleSize != null)
            .animate()
            .fadeIn(delay: 160.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms),
      ],
    );
  }

  Widget _actionsBlock({
    required TextStyle? legalStyle,
    required TextStyle? linkStyle,
    required bool compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: legalStyle,
            children: [
              const TextSpan(
                text:
                    'Al tocar Continuar, aceptás los ',
              ),
              TextSpan(
                text: 'Términos y condiciones',
                style: linkStyle,
                recognizer: _termsRecognizer,
              ),
              const TextSpan(text: '. Conocé cómo usamos tus datos en nuestra '),
              TextSpan(
                text: 'Política de privacidad',
                style: linkStyle,
                recognizer: _privacyRecognizer,
              ),
              const TextSpan(text: ' y '),
              TextSpan(
                text: 'Política de cookies',
                style: linkStyle,
                recognizer: _cookiesRecognizer,
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),
        SizedBox(height: compact ? 12 : 20),
        WelcomeAuthButton(
          label: 'Continuar con email',
          icon: const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => context.push('/login'),
        )
            .animate()
            .fadeIn(delay: 280.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        WelcomeAuthButton(
          label: 'Continuar con Google',
          icon: const GoogleLogo(size: 24),
          onPressed: _showComingSoon,
        )
            .animate()
            .fadeIn(delay: 340.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0, duration: 400.ms),
        SizedBox(height: compact ? 12 : 20),
        TindogTextButton(
          onPressed: _openForgotPassword,
          foregroundColor: Colors.white,
          fontWeight: FontWeight.w700,
          child: const Text('¿No podés iniciar sesión?'),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _privacyRecognizer.onTap = _openPrivacy;
    _cookiesRecognizer.onTap = _openCookies;
    _termsRecognizer.onTap = _openTerms;

    final legalStyle = _legalStyle(context);
    final linkStyle = legalStyle?.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      body: TindogGradientBackground(
        gradient: AppGradients.authHero,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
            final compact = constraints.maxHeight < 560;
            final logoSize = compact ? 72.0 : 120.0;
            const horizontalPadding = 28.0;

            if (compact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _brandBlock(logoSize: logoSize, titleSize: 24),
                    const SizedBox(height: 24),
                    _actionsBlock(
                      legalStyle: legalStyle,
                      linkStyle: linkStyle,
                      compact: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.10),
                  _brandBlock(logoSize: logoSize),
                  const Spacer(),
                  _actionsBlock(
                    legalStyle: legalStyle,
                    linkStyle: linkStyle,
                    compact: false,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
          ),
        ),
      ),
    );
  }
}
