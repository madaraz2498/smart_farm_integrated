import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      // Responsive column count
      final isWide = constraints.maxWidth > 700;
      final crossAxisCount = isWide ? 4 : 2;
      final spacing = 16.0;
      
      // Dynamic aspect ratio to prevent clipping - adjusted for user management page
      final childAspectRatio = isWide ? 1.4 : 2.0;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return _StatCard(data: cards[index]);
        },
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start, // Align to top
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (data.svgPath != null)
                SvgPicture.asset(
                  data.svgPath!,
                  width: 24, // Slightly smaller icons for better fit
                  height: 24,
                )
              else
                Icon(data.icon, color: data.color, size: 24),
            ],
          ),
          const Spacer(), // Push value to bottom
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 20, // Slightly smaller font
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
