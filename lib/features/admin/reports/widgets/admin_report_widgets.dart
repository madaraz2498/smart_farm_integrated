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

  const AdminChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.height = 350,
    this.actions,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: textTheme.bodySmall),
                  ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final List<Color> colors = [
      colorScheme.primary,
      const Color(0xFF66BB6A),
      const Color(0xFF81C784),
      const Color(0xFFA5D6A7),
      const Color(0xFFC8E6C9),
      const Color(0xFFE8F5E9),
    ];

    return AdminChartCard(
      title: l10n.service_distribution,
      subtitle: l10n.usage_by_ai_service,
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
                      sections: _buildSections(colors),
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
                      children: _buildLegend(l10n, colors),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<PieChartSectionData> _buildSections(List<Color> colors) {
    return List.generate(data.length, (i) {
      return PieChartSectionData(
        value: data[i].count.toDouble(),
        color: colors[i % colors.length],
        radius: 35,
        showTitle: false,
      );
    });
  }

  List<Widget> _buildLegend(AppLocalizations l10n, List<Color> colors) {
    final total = data.fold(0, (sum, e) => sum + e.count);
    return List.generate(data.length, (i) {
      final item = data[i];
      final pct =
          total > 0 ? (item.count / total * 100).toStringAsFixed(0) : '0';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: colors[i % colors.length], shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LabelMapper.getLocalizedService(item.service, l10n),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('$pct%',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
