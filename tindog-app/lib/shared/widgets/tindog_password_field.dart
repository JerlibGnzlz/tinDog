import 'package:flutter/material.dart';

class TindogPasswordField extends StatefulWidget {
  const TindogPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.externalError,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.autofillHints = const [AutofillHints.password],
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? externalError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final String? helperText;

  @override
  State<TindogPasswordField> createState() => _TindogPasswordFieldState();
}

class _TindogPasswordFieldState extends State<TindogPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      scrollPadding: const EdgeInsets.all(96),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorText: widget.externalError,
        errorMaxLines: 2,
        suffixIcon: IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _obscure = !_obscure)
              : null,
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
      ),
    );
  }
}
