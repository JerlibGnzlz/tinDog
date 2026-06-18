import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../shared/widgets/app_tagline.dart';
import '../../../shared/widgets/auth_error_banner.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_password_field.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import 'auth_provider.dart';
import 'auth_validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearFailure() => ref.read(authFailureProvider.notifier).state = null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFailure();
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authSessionProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      AppHaptics.success();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final failure = ref.watch(authFailureProvider);
    final isLoading = authState.isLoading;
    final fieldErrors = failure?.fieldErrors;

    return AuthScaffold(
      title: 'Bienvenido a tinDog',
      subtitle: const AppTagline(onDark: false),
      showBackButton: true,
      onBack: () => context.go('/auth/email'),
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null &&
                (fieldErrors == null || fieldErrors.isEmpty)) ...[
              AuthErrorBanner(message: failure.message),
              const SizedBox(height: 16),
            ],
            TindogTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              enabled: !isLoading,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              externalError: authFieldError(fieldErrors, 'email'),
              onChanged: (_) => _clearFailure(),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TindogPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !isLoading,
              label: 'Contraseña',
              textInputAction: TextInputAction.done,
              externalError: authFieldError(fieldErrors, 'password'),
              onChanged: (_) => _clearFailure(),
              onFieldSubmitted: (_) => _submit(),
              validator: validateLoginPassword,
            ),
            const SizedBox(height: 28),
            TindogFilledButton(
              onPressed: _submit,
              loading: isLoading,
              child: const Text('Entrar'),
            ),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/register'),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
