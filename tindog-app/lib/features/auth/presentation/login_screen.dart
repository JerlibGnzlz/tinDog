import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/auth_error_banner.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/tindog_password_field.dart';
import '../../../shared/widgets/tindog_text_field.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authFailureProvider.notifier).state = null;
    setState(() => _autovalidateMode = AutovalidateMode.always);
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authSessionProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final failure = ref.watch(authFailureProvider);

    return AuthScaffold(
      title: 'Bienvenido a tinDog',
      subtitle: 'Encuentra el mejor amigo para tu mascota',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null) ...[
              AuthErrorBanner(message: failure.message),
              const SizedBox(height: 16),
            ],
            if (kDebugMode) ...[
              AuthHintBanner(
                apiBaseUrl: AppConstants.apiBaseUrl,
                onUseTestAccount: () async {
                  _emailController.text = 'lucas@tindog.test';
                  _passwordController.text = 'password123';
                  await _submit();
                },
              ),
              const SizedBox(height: 16),
            ],
            TindogTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => ref.read(authFailureProvider.notifier).state = null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El email es requerido';
                }
                if (!value.contains('@')) return 'Ingresa un email válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TindogPasswordField(
              controller: _passwordController,
              label: 'Contraseña',
              onChanged: (_) => ref.read(authFailureProvider.notifier).state = null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es requerida';
                }
                if (value.length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: authState.isLoading ? null : _submit,
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Entrar'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
