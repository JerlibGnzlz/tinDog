import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_error_banner.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/legal_links_text.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_text_button.dart';
import '../../../shared/widgets/tindog_password_field.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import 'auth_provider.dart';
import 'auth_validators.dart';
import 'password_strength.dart';

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
  bool _acceptedTerms = false;
  String? _termsError;

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

  void _revalidateForm() {
    if (_autovalidateMode == AutovalidateMode.disabled &&
        _confirmController.text.isEmpty) {
      return;
    }
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFailure();
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!_acceptedTerms) {
      setState(() => _termsError = 'Debés aceptar los términos para continuar');
      return;
    }
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
    final passwordStrength =
        evaluatePasswordStrength(_passwordController.text);

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
      onBack: () => context.go('/login'),
        child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: AutofillGroup(
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
              autofillHints: const [AutofillHints.email, AutofillHints.username],
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
                setState(() {});
                _revalidateForm();
              },
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              validator: validateRegisterPassword,
            ),
            PasswordStrengthIndicator(strength: passwordStrength),
            const SizedBox(height: 16),
            TindogPasswordField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              enabled: !isLoading,
              label: 'Confirmar contraseña',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) {
                _clearFailure();
                _revalidateForm();
              },
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  validateConfirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() {
                            _acceptedTerms = value ?? false;
                            _termsError = null;
                          }),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LegalLinksText(
                      prefix: 'Acepto los ',
                      compact: true,
                    ),
                  ),
                ),
              ],
            ),
            if (_termsError != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _termsError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TindogFilledButton(
              onPressed: _submit,
              loading: isLoading,
              child: const Text('Registrarme'),
            ),
            TindogTextButton(
              onPressed: isLoading ? null : () => context.go('/login'),
              child: const Text('Ya tengo cuenta'),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
