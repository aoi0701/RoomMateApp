import 'package:flutter/material.dart';

class AmenityGrid extends StatelessWidget {
  final List<String> amenities;
  final Set<String> selectedAmenities;
  final ValueChanged<String>? onToggle;
  final bool enabled;
  final bool singleRow;
  final double singleRowItemWidth;
  final int? fixedColumns;

  const AmenityGrid({
    super.key,
    required this.amenities,
    this.selectedAmenities = const {},
    this.onToggle,
    this.enabled = true,
    this.singleRow = false,
    this.singleRowItemWidth = 108,
    this.fixedColumns,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAmenities = amenities
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    if (visibleAmenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (singleRow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < visibleAmenities.length; i++) ...[
                  SizedBox(
                    width: singleRowItemWidth,
                    child: _AmenityTile(
                      label: visibleAmenities[i],
                      icon: AmenityCatalog.resolve(visibleAmenities[i]).icon,
                      selected: selectedAmenities.contains(visibleAmenities[i]),
                      enabled: enabled,
                      onTap: onToggle == null
                          ? null
                          : () => onToggle!(visibleAmenities[i]),
                    ),
                  ),
                  if (i != visibleAmenities.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            ),
          );
        }

        final columns = fixedColumns ?? (constraints.maxWidth >= 420 ? 4 : 3);
        final itemWidth = (constraints.maxWidth - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: visibleAmenities.map((item) {
            final data = AmenityCatalog.resolve(item);
            return SizedBox(
              width: itemWidth,
              child: _AmenityTile(
                label: item,
                icon: data.icon,
                selected: selectedAmenities.contains(item),
                enabled: enabled,
                onTap: onToggle == null ? null : () => onToggle!(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class AmenityCatalog {
  static AmenityVisual resolve(String label) {
    switch (label.trim()) {
      case 'C\u00F3 m\u00E1y l\u1EA1nh':
        return const AmenityVisual(Icons.ac_unit_rounded);
      case 'Kh\u00F4ng m\u00E1y l\u1EA1nh':
        return const AmenityVisual(Icons.mode_fan_off_rounded);
      case 'Nu\u00F4i th\u00FA c\u01B0ng':
        return const AmenityVisual(Icons.pets_rounded);
      case 'C\u00F3 g\u00E1c':
        return const AmenityVisual(Icons.layers_rounded);
      case 'Kh\u00F4ng g\u00E1c':
        return const AmenityVisual(Icons.layers_clear_rounded);
      case 'C\u00F3 ban c\u00F4ng':
        return const AmenityVisual(Icons.balcony_rounded);
      case 'C\u00F3 ch\u1ED7 \u0111\u1EC3 xe':
        return const AmenityVisual(Icons.local_parking_rounded);
      case 'C\u00F3 n\u1ED9i th\u1EA5t':
        return const AmenityVisual(Icons.chair_rounded);
      case 'C\u00F3 m\u00E1y gi\u1EB7t':
        return const AmenityVisual(Icons.local_laundry_service_rounded);
      case 'C\u00F3 b\u1EBFp':
        return const AmenityVisual(Icons.soup_kitchen_rounded);
      default:
        return const AmenityVisual(Icons.checkroom_rounded);
    }
  }
}

class AmenityVisual {
  final IconData icon;

  const AmenityVisual(this.icon);
}

class _AmenityTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _AmenityTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? const Color(0xFF2F6BFF) : const Color(0xFF5B6475);
    final background =
        selected ? const Color(0xFFEAF1FF) : const Color(0xFFF6F8FC);
    final border =
        selected ? const Color(0xFF2F6BFF) : const Color(0xFFD8DEE9);

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF173A6A)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
