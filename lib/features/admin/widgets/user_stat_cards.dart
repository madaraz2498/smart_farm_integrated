import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_farm/core/utils/responsive.dart';

class StatCardData {
  final String label;
  final String value;
  final String? svgPath;
  final IconData? icon;
  final Color color;

  StatCardData({
    required this.label,
    required this.value,
    this.svgPath,
    this.icon,
    required this.color,
  });
}

class AdminStatCards extends StatelessWidget {
  final List<StatCardData> cards;
  const AdminStatCards({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = Responsive.isMobile(context) ? 1 : 2;
      final spacing = Responsive.responsiveSpacing(context);
      final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cards.map((c) => _StatCard(data: c, width: cardWidth)).toList(),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final StatCardData data;
  final double width;
  const _StatCard({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: 4),
              if (data.svgPath != null)
                SvgPicture.asset(
                  data.svgPath!,
                  width: 32,
                  height: 32,
                )
              else
                Icon(data.icon, color: data.color, size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
