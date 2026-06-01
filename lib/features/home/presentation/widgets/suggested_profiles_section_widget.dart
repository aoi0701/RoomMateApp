import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/roommate_profile_model.dart';
import '../viewmodels/roommate_profile_viewmodel.dart';

class SuggestedProfilesSectionWidget extends StatelessWidget {
  final void Function(RoommateProfileModel) onViewProfile;
  final void Function(RoommateProfileModel) onInviteTap;

  const SuggestedProfilesSectionWidget({
    super.key,
    required this.onViewProfile,
    required this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    final roommateVm = context.watch<RoommateProfileViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Gợi ý bạn ở ghép', style: AppTextStyles.h2),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<RoommateProfileModel>>(
          stream: roommateVm.suggestedProfilesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _ProfileCardShimmer(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InlineMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Không tải được gợi ý',
                  subtitle: '${snapshot.error}',
                ),
              );
            }

            final profiles = snapshot.data ?? const <RoommateProfileModel>[];
            if (profiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _InlineMessage(
                  icon: Icons.person_search_outlined,
                  title: 'Chưa có hồ sơ phù hợp',
                  subtitle:
                      'Cập nhật thói quen và tiêu chí trong hồ sơ để nhận gợi ý.',
                ),
              );
            }

            final displayed = profiles.take(6).toList();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < displayed.length; i++) ...[
                    _SuggestedProfileCard(
                      profile: displayed[i],
                      isInvited: roommateVm.isInvited(displayed[i].userId),
                      onViewDetail: () => onViewProfile(displayed[i]),
                      onInviteTap: roommateVm.isInvited(displayed[i].userId)
                          ? null
                          : () => onInviteTap(displayed[i]),
                    ),
                    if (i < displayed.length - 1) const SizedBox(width: 16),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _SuggestedProfileCard extends StatelessWidget {
  final RoommateProfileModel profile;
  final VoidCallback onViewDetail;
  final VoidCallback? onInviteTap;
  final bool isInvited;

  const _SuggestedProfileCard({
    required this.profile,
    required this.onViewDetail,
    required this.isInvited,
    this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 236,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + name + location
                  Row(
                    children: [
                      AppAvatar(
                        name: profile.displayName,
                        avatarUrl: profile.avatarUrl,
                        size: 48,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.label.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    profile.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Match progress bar
                  _MatchBar(percentage: profile.matchPercentage),
                  const SizedBox(height: 10),
                  // Habit tags
                  if (profile.habits.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: profile.habits
                          .take(3)
                          .map((h) => _TagChip(label: h))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ] else
                    const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: FilledButton(
                            onPressed: onViewDetail,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              textStyle: AppTextStyles.buttonSm.copyWith(
                                fontSize: 14,
                                height: 1.2,
                              ),
                              minimumSize: const Size(0, 42),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Xem chi tiết'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 42,
                        width: 42,
                        child: OutlinedButton(
                          onPressed: onInviteTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isInvited
                                ? AppColors.successText
                                : AppColors.primary,
                            side: BorderSide(
                              color: isInvited
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            backgroundColor: isInvited
                                ? AppColors.successSurface
                                : null,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(42, 42),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Icon(
                            isInvited
                                ? Icons.check_rounded
                                : Icons.person_add_alt_1_outlined,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _MatchBar extends StatelessWidget {
  final int percentage;
  const _MatchBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final ratio = (percentage / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage% phù hợp',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ProfileCardShimmer extends StatelessWidget {
  const _ProfileCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (idx) {
          return Container(
            width: 220,
            margin: EdgeInsets.only(right: idx < 2 ? 16 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _ShimmerBox(
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(width: 110, height: 13),
                        const SizedBox(height: 8),
                        _ShimmerBox(width: 70, height: 11),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ShimmerBox(width: double.infinity, height: 32),
                const SizedBox(height: 10),
                _ShimmerBox(width: 160, height: 22),
                const SizedBox(height: 12),
                _ShimmerBox(width: double.infinity, height: 38),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFE2E8F0),
            const Color(0xFFF1F5F9),
            _animation.value,
          ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
