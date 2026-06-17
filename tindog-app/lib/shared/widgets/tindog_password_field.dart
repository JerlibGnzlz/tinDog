import 'package:flutter/material.dart';

class TindogPasswordField extends StatefulWidget {
  const TindogPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.externalError,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? externalError;
  final ValueChanged<String>? onChanged;

  @override
  State<TindogPasswordField> createState() => _TindogPasswordFieldState();
}

class _TindogPasswordFieldState extends State<TindogPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.externalError,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
      ),
    );
  }
}
