import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    // required this.suffixIcon,
    // required this.onSubmitted,
    required this.onChanged, required this.suffixIcon,
  });

  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget suffixIcon;
  // final Widget? suffixIcon;
  // final void Function(String)? onSubmitted;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      child: TextField(
        maxLines: 1,
        // onSubmitted: onSubmitted,
        onChanged: onChanged,
        // keyboardType: const TextInputType.numberWithOptions(),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(14),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              // More visible neutral border when not focused
              color: theme.colorScheme.onSurface.withOpacity(0.28),
              width: 1.1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.error,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
            focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.6),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: theme.colorScheme.surface,
          filled: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Icon(
              Icons.search,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.45),
            fontWeight: FontWeight.w400,
          ),
        ),
        // decoration: InputDecoration(
        //   contentPadding:
        //       const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        //   border: OutlineInputBorder(
        //       borderSide: BorderSide.none,
        //       borderRadius: BorderRadius.circular(8)),
        //   fillColor: AppColors.whiteColor,
        //   filled: filled,
        //   suffixIcon: Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 12),
        //     child: IconButton(icon: Icon(Icons.search), onPressed: () => onSearch(),),
        //   ),
        //   hintText: hintText,
        //   hintStyle: AppStyles.f14w4,
        // ),
  style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
        obscureText: false,
        controller: controller,
        focusNode: focusNode,
      ),
    );
  }
}
