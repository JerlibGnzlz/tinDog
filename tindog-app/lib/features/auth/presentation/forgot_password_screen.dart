import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_error_banner.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_text_button.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import '../data/auth_exception.dart';
import '../data/auth_repository.dart';
import 'auth_validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail.isNotEmpty) {
      _emailController.text = widget.initialEmail.trim().toLowerCase();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  TextStyle? _helperStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errorMessage = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();

    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      AppHaptics.success();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    }
  }

  void _goToReset() {
    final email = Uri.encodeComponent(_emailController.text.trim().toLowerCase());
    context.go('/reset-password?email=$email');
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim().toLowerCase();

    return AuthScaffold(
      title: _emailSent ? 'Revisá tu email' : 'Recuperar contraseña',
      subtitle: Text(
        _emailSent
            ? 'Si $email está registrado en tinDog, te enviamos un código de 6 dígitos. Vence en 15 minutos.'
            : 'Te enviaremos un código para restablecer tu contraseña.',
        textAlign: TextAlign.center,
      ),
      showBackButton: true,
      onBack: () => context.go('/login'),
      child: _emailSent ? _buildSentState() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            AuthErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],
          Text(
            'Usá el mismo email con el que te registraste en tinDog.',
            style: _helperStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TindogTextField(
            controller: _emailController,
            enabled: !_isLoading,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onChanged: (_) => setState(() => _errorMessage = null),
            onFieldSubmitted: (_) => _submit(),
            validator: validateEmail,
          ),
          const SizedBox(height: 24),
          TindogFilledButton(
            onPressed: _submit,
            loading: _isLoading,
            child: const Text('Enviar código'),
          ),
          TindogTextButton(
            onPressed: _isLoading ? null : () => context.go('/register'),
            child: const Text('¿No tenés cuenta? Crear cuenta'),
          ),
          TindogTextButton(
            onPressed: _isLoading ? null : () => context.go('/login'),
            child: const Text('Volver al login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSentState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Si no recibís el código en unos minutos, revisá la carpeta de spam '
          'y verificá que el email sea el correcto.',
          style: _helperStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '¿Nunca te registraste con este email? Creá una cuenta nueva.',
          style: _helperStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TindogFilledButton(
          onPressed: _goToReset,
          child: const Text('Ingresar código'),
        ),
        TindogTextButton(
          onPressed: _isLoading ? null : () => context.go('/register'),
          child: const Text('Crear cuenta'),
        ),
        TindogTextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _emailSent = false;
                    _errorMessage = null;
                  }),
          child: const Text('Usar otro email'),
        ),
      ],
    );
  }
}
