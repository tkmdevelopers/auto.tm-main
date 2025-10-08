import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';

class STextField extends StatelessWidget {
  const STextField({
    super.key,
    this.isObscure = false,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.onSubmitted, this.type,
    this.textAlign, this.onChanged,
  });

  final bool isObscure;
  final String? hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final TextInputType? type;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
        final theme = Theme.of(context);

    return TextField(
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      keyboardType: type,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.textFieldBorderColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.secondaryColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primaryColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        fillColor: theme.colorScheme.primaryContainer,
        filled: true,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textTertiaryColor,
        ),
      ),
      obscureText: isObscure,
      controller: controller,
      focusNode: focusNode,
    );
  }
}
