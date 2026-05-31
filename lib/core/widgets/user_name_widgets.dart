import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_name_cache.dart';
import '../theme/app_text_styles.dart';
import 'app_avatar.dart';

/// Resolves [userId] to a display name via [UserNameCache] and renders it as
/// a [Text]. The underlying Firestore listener is shared across all widgets
/// that request the same [userId] — no duplicate listeners.
class UserNameText extends StatelessWidget {
  final String userId;
  final TextStyle? style;
  final TextOverflow overflow;
  final int maxLines;

  const UserNameText({
    super.key,
    required this.userId,
    this.style,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile>(
      stream: context.read<UserNameCache>().profileStream(userId),
      builder: (_, snapshot) => Text(
        snapshot.data?.name ?? 'Người dùng',
        style: style ?? AppTextStyles.label,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}

/// Resolves [userId] to an avatar + name row via [UserNameCache].
class UserNameTile extends StatelessWidget {
  final String userId;
  final double avatarSize;

  const UserNameTile({
    super.key,
    required this.userId,
    this.avatarSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile>(
      stream: context.read<UserNameCache>().profileStream(userId),
      builder: (_, snapshot) {
        final profile = snapshot.data ?? UserProfile.fallback;
        return Row(
          children: [
            AppAvatar(
              name: profile.name,
              avatarUrl: profile.avatarUrl,
              size: avatarSize,
            ),
            const SizedBox(width: 12),
            Text(profile.name, style: AppTextStyles.labelLg),
          ],
        );
      },
    );
  }
}
