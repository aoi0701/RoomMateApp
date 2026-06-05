import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_name_cache.dart';
import '../theme/app_text_styles.dart';
import 'app_avatar.dart';

// Widget hiển thị tên user theo userId: dùng UserNameCache nên không tạo thêm Firestore listener
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

// Widget hiển thị hàng avatar + tên user theo userId, cũng dùng UserNameCache
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
