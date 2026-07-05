import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';

class EdgeLabel extends StatelessWidget {
  const EdgeLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(), style: AppTheme.label()),
    );
  }
}

class EdgeInput extends StatelessWidget {
  const EdgeInput({
    super.key,
    this.controller,
    this.hint,
    this.leadingIcon,
    this.obscureText = false,
    this.trailing,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? leadingIcon;
  final bool obscureText;
  final Widget? trailing;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final TextAlign textAlign;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      enabled: enabled,
      textAlign: textAlign,
      maxLength: maxLength,
      style: AppTheme.sans(size: 14, color: Colors.white),
      cursorColor: EdgeColors.accent,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: leadingIcon == null
            ? null
            : Icon(leadingIcon,
                size: 16, color: EdgeColors.muted),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: trailing,
      ),
    );
  }
}
