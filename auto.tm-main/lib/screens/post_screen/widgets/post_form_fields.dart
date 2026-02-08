import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A titled section card used to group related form fields in the post form.
class PostSectionCard extends StatelessWidget {
  const PostSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurface, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

/// A small label with an optional red asterisk for required fields.
class PostLabel extends StatelessWidget {
  const PostLabel(this.label, {super.key, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          children: [
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A read-only selectable field that opens a picker (bottom sheet, page, etc.)
/// when tapped. Displays an arrow icon and optional leading icon.
class PostSelectableField extends StatelessWidget {
  const PostSelectableField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.enabled = true,
    this.isRequired = false,
    this.icon,
    this.errorText,
  });

  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;
  final bool enabled;
  final bool isRequired;
  final IconData? icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostLabel(label, isRequired: isRequired),
          InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: enabled ? 0.05 : 0.03,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText == null
                      ? (enabled
                            ? theme.colorScheme.outline
                                .withValues(alpha: 0.3)
                            : theme.colorScheme.outline
                                .withValues(alpha: 0.15))
                      : theme.colorScheme.error,
                ),
              ),
              child: Row(
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      color: !enabled
                          ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)
                          : (errorText == null
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.error),
                      size: 20,
                    ),
                  if (icon != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value.isEmpty ? hint : value,
                      style: TextStyle(
                        color: !enabled
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.3)
                            : (value.isEmpty
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5)
                                  : theme.colorScheme.onSurface),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: !enabled
                        ? theme.colorScheme.onSurface
                            .withValues(alpha: 0.25)
                        : (errorText == null
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)
                              : theme.colorScheme.error),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                errorText!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A themed [TextFormField] with a label, used across the post form.
///
/// Pass [onFieldChanged] to be notified when the text content changes
/// (after the optional [validatorFn] runs).
class PostTextFormField extends StatelessWidget {
  const PostTextFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.hint,
    this.isRequired = false,
    this.maxLines = 1,
    this.prefixText,
    this.suffix,
    this.inputFormatters,
    this.validatorFn,
    this.onFieldChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final String? prefixText;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? validatorFn;

  /// Called after each text change (and after [validatorFn], if any).
  final VoidCallback? onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostLabel(label, isRequired: isRequired),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.normal,
              ),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              suffixIcon: suffix,
              filled: true,
              fillColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) {
              if (validatorFn != null) {
                validatorFn!(v.trim());
              }
              onFieldChanged?.call();
            },
          ),
        ],
      ),
    );
  }
}
