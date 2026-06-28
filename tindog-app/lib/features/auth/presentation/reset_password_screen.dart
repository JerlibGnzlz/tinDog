import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_error_banner.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_password_field.dart';
import '../../../shared/widgets/tindog_text_button.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import '../data/auth_exception.dart';
import '../data/auth_repository.dart';
import 'auth_validators.dart';
import 'password_strength.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String>? _fieldErrors;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearErrors() {
    _errorMessage = null;
    _fieldErrors = null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _clearErrors();
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    final codeError = validateResetCode(_codeController.text);
    if (codeError != null) {
      setState(() => _fieldErrors = {'code': codeError});
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: widget.email,
            code: _codeController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      AppHaptics.success();
      showTindogSuccessSnackBar(
        context,
        'Contraseña actualizada. Ya podés iniciar sesión.',
      );
      context.go('/login');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.fieldErrors == null || e.fieldErrors!.isEmpty
            ? e.message
            : null;
        _fieldErrors = e.fieldErrors;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength =
        evaluatePasswordStrength(_passwordController.text);
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    return AuthScaffold(
      title: 'Nueva contraseña',
      subtitle: Text(
        'Ingresá el código enviado a ${widget.email}',
        textAlign: TextAlign.center,
      ),
      showBackButton: true,
      onBack: () => context.go('/forgot-password'),
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AuthErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            TindogTextField(
              controller: _emailController,
              enabled: false,
              label: 'Email',
            ),
            const SizedBox(height: 20),
            Text(
              'Código de 6 dígitos',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Pinput(
              controller: _codeController,
              length: 6,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration?.copyWith(
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration?.copyWith(
                  border: Border.all(color: Colors.red.shade400, width: 2),
                ),
              ),
              forceErrorState: authFieldError(_fieldErrors, 'code') != null,
              onChanged: (_) => setState(_clearErrors),
              validator: (value) => validateResetCode(value),
            ),
            if (authFieldError(_fieldErrors, 'code') != null) ...[
              const SizedBox(height: 8),
              Text(
                authFieldError(_fieldErrors, 'code')!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TindogPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_isLoading,
              label: 'Nueva contraseña',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              helperText: 'Mínimo 8 caracteres',
              externalError: authFieldError(_fieldErrors, 'password'),
              onChanged: (_) {
                _clearErrors();
                setState(() {});
              },
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              validator: validateRegisterPassword,
            ),
            PasswordStrengthIndicator(strength: passwordStrength),
            const SizedBox(height: 16),
            TindogPasswordField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              enabled: !_isLoading,
              label: 'Confirmar contraseña',
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(_clearErrors),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) =>
                  validateConfirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 24),
            TindogFilledButton(
              onPressed: _submit,
              loading: _isLoading,
              child: const Text('Restablecer contraseña'),
            ),
            TindogTextButton(
              onPressed: _isLoading ? null : () => context.go('/forgot-password'),
              child: const Text('Pedir nuevo código'),
            ),
          ],
        ),
      ),
    );
  }
}
