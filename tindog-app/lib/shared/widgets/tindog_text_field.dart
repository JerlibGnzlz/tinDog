import 'package:flutter/material.dart';

class TindogTextField extends StatelessWidget {
  const TindogTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.focusNode,
    this.externalError,
    this.enabled = true,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? externalError;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: autocorrect,
      autofillHints: autofillHints,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      scrollPadding: const EdgeInsets.all(96),
      decoration: InputDecoration(
        labelText: label,
        errorText: externalError,
        errorMaxLines: 2,
      ),
    );
  }
}
