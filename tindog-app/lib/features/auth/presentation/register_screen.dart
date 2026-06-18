import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_error_banner.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_password_field.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import 'auth_provider.dart';
import 'auth_validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearFailure() => ref.read(authFailureProvider.notifier).state = null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFailure();
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authSessionProvider.notifier).register(
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
      title: 'Crea tu cuenta',
      subtitle: Text(
        'Únete a la comunidad tinDog',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              helperText: 'Mínimo 8 caracteres',
              externalError: authFieldError(fieldErrors, 'password'),
              onChanged: (_) {
                _clearFailure();
                if (_autovalidateMode != AutovalidateMode.disabled) {
                  _formKey.currentState?.validate();
                }
              },
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              validator: validateRegisterPassword,
            ),
            const SizedBox(height: 16),
            TindogPasswordField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              enabled: !isLoading,
              label: 'Confirmar contraseña',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => _clearFailure(),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  validateConfirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 28),
            TindogFilledButton(
              onPressed: _submit,
              loading: isLoading,
              child: const Text('Registrarme'),
            ),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/login'),
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
