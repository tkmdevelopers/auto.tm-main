import 'package:auto_tm/ui_components/colors.dart';
import 'package:flutter/material.dart';

class SRefreshIndicator extends StatelessWidget {
  const SRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });
  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
        final theme = Theme.of(context);

    return RefreshIndicator.adaptive(
      color: AppColors.primaryColor,
      backgroundColor: theme.colorScheme.surface,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
