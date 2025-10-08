import 'package:auto_tm/ui_components/colors.dart';
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
        prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.search, color: theme.colorScheme.primary,),
          ),
          suffixIcon: suffixIcon,
          // suffixIcon: IconButton(icon: Icon(Icons.close_rounded, color: AppColors.textTertiaryColor,), onPressed: () => controller.text = '',),
        // prefix: const Padding(
        //   padding: EdgeInsets.only(right: 8.0),
        //   child: Text(
        //     "+993",
        //     style: TextStyle(color: Colors.black),
        //   ),
        // ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textTertiaryColor,
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
        style: TextStyle(fontWeight: FontWeight.w500, color: theme.colorScheme.primary),
        obscureText: false,
        controller: controller,
        focusNode: focusNode,
      ),
    );
  }
}
