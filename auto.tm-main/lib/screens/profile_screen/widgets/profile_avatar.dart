import 'dart:typed_data';
import 'package:auto_tm/utils/key.dart';
import 'package:flutter/material.dart';

/// Reusable avatar widget handling three states:
/// 1. Local picked image (Uint8List)
/// 2. Remote avatar path (absolute http(s) or relative path combined with ApiKey.ip)
/// 3. Placeholder (person icon)
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.localBytes,
    this.remotePath,
    this.radius = 40,
    this.backgroundRadiusDelta = 4,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
    this.onTap,
  });

  final Uint8List? localBytes;
  final String? remotePath;
  final double radius;
  final double backgroundRadiusDelta; // difference between outer and inner
  final Color? backgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback? onTap;

  bool get _hasRemote => remotePath != null && remotePath!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outerRadius = radius + backgroundRadiusDelta;
    Widget inner;

    if (localBytes != null) {
      inner = CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(localBytes!),
      );
    } else if (_hasRemote) {
      final path = remotePath!;
      final url = path.startsWith('http') ? path : '${ApiKey.ip}$path';
      inner = CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    } else {
      inner = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          size: iconSize ?? (radius * 0.8),
          color: iconColor ?? theme.colorScheme.primary,
        ),
      );
    }

    final avatar = CircleAvatar(
      radius: outerRadius,
      backgroundColor: Colors.white,
      child: inner,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(outerRadius),
        child: avatar,
      );
    }
    return avatar;
  }
}
