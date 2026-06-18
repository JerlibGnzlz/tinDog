import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_logo.dart';
import 'tindog_back_button.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final Widget subtitle;
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: showBackButton
          ? AppBar(
              leading: TindogBackButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              leadingWidth: 48,
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AnimatedAppLogo(size: 96)),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyMedium,
                  child: Center(child: subtitle),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 40),
                child
                    .animate()
                    .fadeIn(delay: 280.ms, duration: 450.ms)
                    .slideY(
                      begin: 0.05,
                      end: 0,
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
