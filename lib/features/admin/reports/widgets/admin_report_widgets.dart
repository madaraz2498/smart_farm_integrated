// lib/features/admin/reports/widgets/admin_report_widgets.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import '../models/report_model.dart';
import '../utils/label_mapper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminChartCard — A professional container for all dashboard charts.
// ─────────────────────────────────────────────────────────────────────────────
class AdminChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double height;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;

  const AdminChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.height = 350,
    this.actions,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
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
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor ?? colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade500)),
                      ],
                    ],
                  ),
                ],
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserGrowthChart — Line chart showing user registrations over time.
// ─────────────────────────────────────────────────────────────────────────────
class UserGrowthChart extends StatelessWidget {
  final List<UserGrowth> data;
  const UserGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    double maxY = 100;
    if (data.isNotEmpty) {
      final maxVal = data.map((e) => e.users).reduce((a, b) => a > b ? a : b);
      maxY = (maxVal > 80 ? (maxVal * 1.2).toDouble() : 100);
    }

    return AdminChartCard(
      title: l10n.user_growth,
      subtitle: l10n.new_user_registrations,
      icon: Icons.trending_up_outlined,
      iconColor: const Color(0xFF6366F1),
      child: data.isEmpty
          ? const Center(child: Text('No growth data available'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 40,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: textTheme.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= data.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                              LabelMapper.getLocalizedMonth(
                                  data[value.toInt()].month, l10n),
                              style: textTheme.labelSmall),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(data.length,
                        (i) => FlSpot(i.toDouble(), data[i].users.toDouble())),
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ServiceDistributionChart — Donut chart for AI service usage.
// ─────────────────────────────────────────────────────────────────────────────
class ServiceDistributionChart extends StatelessWidget {
  final List<ServiceUsage> data;
  const ServiceDistributionChart({super.key, required this.data});

  Color _getServiceColor(String service, int index) {
    final s = service.toLowerCase();

    // Exact mapping based on keywords (English & Arabic)
    if (s.contains('crop') || s.contains('محاصيل')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    if (s.contains('animal') || s.contains('حيوان')) {
      return const Color(0xFF0EA5E9); // Blue
    }
    if (s.contains('plant') || s.contains('نبات')) {
      return const Color(0xFF22C55E); // Green
    }
    if (s.contains('soil') || s.contains('تربة')) {
      return const Color(0xFFF97316); // Orange
    }
    if (s.contains('fruit') || s.contains('فاكهة')) {
      return const Color(0xFFE11D48); // Pink/Red
    }
    if (s.contains('chat') || s.contains('دردشة')) {
      return const Color(0xFFF59E0B); // Amber
    }

    // Robust Fallback: Never use gray. Use a vibrant color palette based on index.
    final List<Color> fallbackPalette = [
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF0EA5E9), // Blue
      const Color(0xFF22C55E), // Green
      const Color(0xFFF97316), // Orange
      const Color(0xFFE11D48), // Pink/Red
      const Color(0xFFF59E0B), // Amber
    ];

    return fallbackPalette[index % fallbackPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdminChartCard(
      title: l10n.service_distribution,
      subtitle: l10n.usage_by_ai_service,
      icon: Icons.memory_outlined,
      iconColor: const Color(0xFF8B5CF6),
      child: data.isEmpty
          ? const Center(child: Text('No service usage data'))
          : Row(
              children: [
                Expanded(
                  flex: 1,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildSections(l10n),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildLegend(l10n),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<PieChartSectionData> _buildSections(AppLocalizations l10n) {
    return List.generate(data.length, (i) {
      final item = data[i];
      return PieChartSectionData(
        value: item.count.toDouble(),
        color: _getServiceColor(item.service, i),
        radius: 35,
        showTitle: false,
      );
    });
  }

  List<Widget> _buildLegend(AppLocalizations l10n) {
    final total = data.fold(0, (sum, e) => sum + e.count);
    return List.generate(data.length, (i) {
      final item = data[i];
      final pct =
          total > 0 ? (item.count / total * 100).toStringAsFixed(1) : '0';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: _getServiceColor(item.service, i),
                  shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LabelMapper.getLocalizedService(item.service, l10n),
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('$pct%',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WeeklyActivityChart — Bar chart for daily user activity.
// ─────────────────────────────────────────────────────────────────────────────
class WeeklyActivityChart extends StatelessWidget {
  final List<DailyActivity> data;
  const WeeklyActivityChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    double maxY = 60;
    if (data.isNotEmpty) {
      final maxVal =
          data.map((e) => e.activity).reduce((a, b) => a > b ? a : b);
      maxY = (maxVal > 50 ? (maxVal * 1.2).toDouble() : 60);
    }

    return AdminChartCard(
      title: l10n.daily_activity,
      subtitle: l10n.platform_activity_past_week,
      icon: Icons.bar_chart_outlined,
      iconColor: const Color(0xFF10B981),
      child: data.isEmpty
          ? const Center(child: Text('No activity data available'))
          : BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxY / 2,
                      getTitlesWidget: (val, meta) => Text(
                        val.toInt().toString(),
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= data.length) {
                          return const SizedBox();
                        }
                        final day = data[value.toInt()].day;
                        final localizedDay =
                            LabelMapper.getLocalizedDay(day, l10n);
                        final label = localizedDay.length > 3
                            ? localizedDay.substring(0, 3)
                            : localizedDay;
                        return Text(
                          label,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(maxY, colorScheme),
              ),
            ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
      double maxY, ColorScheme colorScheme) {
    return List.generate(
        data.length,
        (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].activity.toDouble(),
                  color: colorScheme.primary,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ));
  }
}
