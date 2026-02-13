import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';

class SLoginTextField extends StatelessWidget {
  const SLoginTextField({
    super.key,
    required this.isObscure,
    required this.controller,
    required this.focusNode,
    this.hintText,
  });

  final bool isObscure;
  final String? hintText;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textFieldBorderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            '+993',
            style: TextStyle(
              color: theme.colorScheme.surface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: isObscure,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.colorScheme.surface, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.onSurface,
                hintText: hintText ?? 'Enter your phone number',
                hintStyle: TextStyle(
                  color: AppColors.textTertiaryColor,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                enabledBorder:
                    InputBorder.none, // we already have container border
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
