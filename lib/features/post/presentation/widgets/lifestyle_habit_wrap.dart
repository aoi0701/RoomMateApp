import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../profile/data/models/profile_habit_model.dart';

class LifestyleHabitWrap extends StatelessWidget {
  final List<String> habitIds;
  final WrapAlignment alignment;
  final bool equalWidth;
  final int columns;

  const LifestyleHabitWrap({
    super.key,
    required this.habitIds,
    this.alignment = WrapAlignment.start,
    this.equalWidth = false,
    this.columns = 2,
  });

  static const Color _fallbackBackground = Color(0xFFF0F4FB);
  static const Color _fallbackForeground = Color(0xFF5B6475);

  @override
  Widget build(BuildContext context) {
    final visibleHabits = habitIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (visibleHabits.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (equalWidth) {
          final safeColumns = columns < 1 ? 1 : columns;
          final itemWidth =
              (constraints.maxWidth - ((safeColumns - 1) * 8)) / safeColumns;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleHabits.map((habitId) {
              final habit = ProfileHabitCatalog.findById(habitId);
              final label = habit?.label ?? habitId;
              final icon = habit?.icon ?? Icons.check_circle_outline_rounded;
              final backgroundColor = habit?.backgroundColor ?? _fallbackBackground;
              final foregroundColor = habit?.foregroundColor ?? _fallbackForeground;

              return SizedBox(
                width: itemWidth,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: foregroundColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: foregroundColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }

        final maxChipWidth = math.min(constraints.maxWidth, 220.0);

        return Wrap(
          alignment: alignment,
          spacing: 8,
          runSpacing: 8,
          children: visibleHabits.map((habitId) {
            final habit = ProfileHabitCatalog.findById(habitId);
            final label = habit?.label ?? habitId;
            final icon = habit?.icon ?? Icons.check_circle_outline_rounded;
            final backgroundColor = habit?.backgroundColor ?? _fallbackBackground;
            final foregroundColor = habit?.foregroundColor ?? _fallbackForeground;

            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 40,
                maxWidth: maxChipWidth,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: foregroundColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: foregroundColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
